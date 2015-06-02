db = require './db'
req = require './req'
log = require './log'
{constants} = require './constants'
{SHA256} = require './keyutils'
{E} = require './err'
{format_fingerprint,Warnings,asyncify} = require('pgp-utils').util
{make_esc} = require 'iced-error'
ST = constants.signature_types
ACCTYPES = constants.allowed_cryptocurrency_types
{dict_union,date_to_unix,make_email} = require './util'
proofs = require 'keybase-proofs'
cheerio = require 'cheerio'
request = require 'request'
colors = require './colors'
deq = require 'deep-equal'
util = require 'util'
{env} = require './env'
scrapemod = require './scrapers'
{CHECK,BTC} = require './display'
{athrow} = require('iced-utils').util
bitcoyne = require 'bitcoyne'

##=======================================================================

exports.Link = class Link

  @ID_TYPE : constants.ids.sig_chain_link

  #--------------------

  constructor : ({@id,@obj}) ->
    @id or= @obj.payload_hash
    @_revoked = false

  #--------------------

  export_to_user : () -> {
    seqno : @seqno()
    payload_hash : @id
    sig_id : @sig_id()
  }

  #--------------------

  prev : () -> @obj.prev
  seqno : () -> @obj.seqno
  sig : () -> @obj.sig
  payload_json_str : () -> @obj.payload_json
  fingerprint : () -> @obj.fingerprint.toLowerCase()
  short_key_id : () -> @fingerprint()[-8...].toUpperCase()
  is_self_sig : () -> false
  self_signer : () -> @payload_json()?.body?.key?.username
  sig_type : () -> @obj.sig_type
  sig_id : () -> @obj.sig_id
  remote_id : () -> @obj.remote_id
  body : () -> @payload_json()?.body
  ctime : () -> date_to_unix @obj.ctime
  revoke : () -> @_revoked = true
  is_revoked : () -> @_revoked

  #--------------------

  to_track_obj : () -> {
    seqno : @seqno()
    sig_id : @sig_id()
    payload_hash : @id
  }

  #--------------------

  payload_json : () ->
    unless @_payload_obj?
      s = @payload_json_str()
      ret = {}
      try
        ret = JSON.parse s
      catch e
        log.error "Error parsing JSON #{s}: #{e.message}"
      @_payload_obj = ret
    return @_payload_obj

  #--------------------

  # Links are nodes in the tree, so no need to keep walking...
  walk : ({fn, parent, key}) -> fn { value : @, key, parent }
  flatten : () -> [ @ ]
  is_leaf : () -> true
  is_revocable : () -> false
  matches : (rxx) -> !!(JSON.stringify(@condense()).match(rxx))
  condense : () -> @payload_json()

  #--------------------

  summary : () -> {
    seqno : @seqno()
    id : @sig_id()
    type : @type_str()
    ctime : @ctime()
    live : not(@is_revoked())
    payload : @condense()
  }

  #--------------------

  verify : () ->
    err = null
    if (a = @obj.payload_hash) isnt (b = @id)
      err = new E.CorruptionError "Link ID mismatch: #{a} != #{b}"
    else if (j = SHA256(@payload_json_str()).toString('hex')) isnt @id
      err = new E.CorruptionError "Link has wrong id: #{@id} != #{@j}"
    return err

  #--------------------

  store : (cb) ->
    @obj.prev = null if @obj.prev?.length is 0
    log.debug "| putting link: #{@id}"
    await db.put { type : Link.ID_TYPE, key : @id, value : @obj }, defer err
    cb err

  #--------------------

  # XXX maybe also refresh the state flag from the server?
  # Only does something for remote proofs...
  refresh : (cb) -> cb null

  #--------------------

  @alloc : ({obj, id}) ->
    klass = switch obj.sig_type
      when ST.SELF_SIG then SelfSig
      when ST.REMOTE_PROOF then RemoteProof
      when ST.TRACK then Track
      when ST.CRYPTOCURRENCY then Cryptocurrency
      when ST.REVOKE then Revoke
      when ST.UNTRACK then Untrack
      else Link
    new klass { obj, id }

  #--------------------

  @load : (id, cb) ->
    ret = null
    await db.get { type : Link.ID_TYPE, key : id }, defer err, obj
    if err? then # noop
    else if obj?
      ret = Link.alloc { id, obj }
      if (err = ret.verify())? then ret = null
    cb err, ret

  #--------------------

  insert_into_table : () ->
    log.warn "unhandled public sig type: #{@sig_type()}"

##=======================================================================

class SelfSig extends Link

  #----------

  is_self_sig : () -> true
  condense : -> "self"
  type_str : -> "self"
  is_revocable : () -> true

  #----------

  insert_into_table : ( {table} ) -> table.insert @sig_type(), @

##=======================================================================

class RemoteProof extends Link

  #-----------

  proof_service_object : () -> @payload_json()?.body?.service
  proof_type : () -> @obj.proof_type
  proof_state : () -> @obj.proof_state
  remote_username : () -> @proof_service_object()?.username
  api_url : () -> @obj.api_url
  human_url : () -> @obj.human_url
  proof_text_check : () -> @obj.proof_text_check

  #-----------

  type_str : () -> "proof"
  is_revocable : () -> true

  #-----------

  condense : () ->
    pso = @proof_service_object()
    key = pso.name or pso.protocol
    key += ":" unless key[-1...][0] is ':'
    val = pso.username or pso.domain or pso.hostname
    [ key, val ].join '//'

  #-----------

  insert_into_table : ({table, index, opts}) ->
    log.debug "+ RemoteProof::insert_into_table"
    S = constants.proof_state
    states = [ S.OK, S.TEMP_FAILURE, S.LOOKING ]
    states.push S.PERM_FAILURE if opts?.show_perm_failures
    if @proof_state() in states
      keys = [ @sig_type(), @proof_type() ]
      if (sub_id = @get_sub_id())? then keys.push sub_id
      table.insert_path keys, @
    else
      log.debug "Skipping remote proof in state #{@proof_state()}: #{@payload_json_str()}"
    log.debug "- RemoteProof::insert_into_table"

  #-----------

  get_sub_id : () ->
    scrapemod.alloc_stub(@proof_type())?.get_sub_id(@proof_service_object())

  #-----------

  check_remote_proof : ({skip, type, warnings, proof_vec}, cb) ->
    username = @self_signer()

    esc = make_esc cb, "SigChain::Link::check_remote_proof'"

    if not (type_s = proofs.proof_type_to_string[type])?
      err = new E.VerifyError "Unknown proof type (#{type}) found; consider a `keybase update`"
      await athrow err, esc defer()

    log.debug "+ #{username}: checking remote #{type_s} proof"

    if not skip and not @api_url()
      await @refresh defer e2
      if e2?
        log.warn "Error fetching URL for proof: #{e2.message}"

    rsc = JSON.stringify @proof_service_object()
    log.debug "| remote service desc is #{rsc}"

    await scrapemod.alloc type, esc defer scraper
    arg =
      api_url : @api_url(),
      signature : @sig(),
      proof_text_check : @proof_text_check()
      remote_id : (""+@remote_id())
      human_url : @human_url()
    arg = dict_union(arg, @proof_service_object())

    # Keep track of this remote proof as a Key-Value pair.
    proof_vec.push scraper.to_proof(arg)

    errmsg = ""
    if skip
      rc = proofs.constants.v_codes.OK
    else if not @api_url()
      rc = proofs.constants.v_codes.NOT_FOUND
    else
      log.debug "+ Calling into scraper -> #{rsc}@#{type_s} -> #{@api_url()}"
      await scraper.validate arg, defer err, rc
      log.debug "- Called scraper -> #{rc}"
      if err?
        errmsg = ": " + err.message

    ok = false
    if rc isnt proofs.constants.v_codes.OK
      warnings.push new E.RemoteCheckError "Remote check failed (code: #{rc})"
      @obj.proof_state = rc
    else
      ok = true
      log.debug "| proof checked out"

    msg = scraper.format_msg { arg, ok }
    msg.push ("(you've recently OK'ed this proof)") if skip
    msg.push "(failed with code #{rc}#{errmsg})" if not ok
    log.lconsole "error", log.package().INFO, msg.join(' ')
    log.debug "- #{username}: checked remote #{type_s} proof"

    cb null

  #------------------

  remote_proof_to_track_obj : () -> {
    ctime : @obj.ctime
    etime : @obj.etime
    seqno : @obj.seqno
    curr : @id
    sig_type : @obj.sig_type
    sig_id : @obj.sig_id
    remote_key_proof :
      check_data_json : @payload_json()?.body?.service
      state : @obj.proof_state
      proof_type : @obj.proof_type
  }

  #----------

  to_list_display : (opts) ->
    name = scrapemod.alloc_stub(@proof_type())?.to_list_display(@proof_service_object())
    if opts?.with_sig_ids or opts?.with_proof_states?
      { name, sig_id : @sig_id(), proof_state : @proof_state() }
    else name

  #----------

  refresh : (cb) ->
    err = null
    log.debug "+ refresh RemoteProof link"
    if not @api_url()?
      log.debug "| Proof_id = #{@obj.proof_id}"
      arg =
        endpoint : "sig/remote_proof"
        args :
          proof_id : @obj.proof_id
      log.debug "| request proof refresh for id=#{@obj.proof_id}"
      await req.get arg, defer err, body
      if not err? and (row = body?.row)? and (u = row.api_url)?
        log.debug "| Refreshed with api_url -> #{u}"
        @obj.api_url = u
        @obj.human_url = row.human_url
        await @store defer err
    log.debug "- refresh RemoteProof link"
    cb err

  #----------

  is_self_sig : () -> true

##=======================================================================

class Track extends Link

  to_table_obj : () ->
    ret = @body().track
    ret.ctime = @ctime()
    return ret

  #----------

  is_self_sig : () -> true

  #----------

  condense : () -> @body().track.basics.username
  type_str : () -> "track"

  #----------

  insert_into_table : ({table, opts}) ->
    log.debug "+ Track::insert_into_table #{@sig_id()}"
    if not (id = @body()?.track?.id)?
      log.warn "Missing track in signature"
      log.debug "Full JSON in signature:"
      log.debug @payload_json_str()
    else
      path = [ @sig_type(), id ]
      # see the comment below about cryptocurrencies
      if opts.show_revoked then path.push @seqno()
      table.insert_path path, @
    log.debug "- Track::insert_into_table #{@sig_id()} (uid=#{id})"

##=======================================================================

class Cryptocurrency extends Link

  to_cryptocurrency : (opts) -> @body()?.cryptocurrency

  #-----------

  condense : () ->
    d = @body().cryptocurrency
    ret = {}
    ret[d.type] = d.address
    return ret

  #-----------

  type_str : () -> "currency"
  is_revocable : () -> true

  #-----------

  display_cryptocurrency : (opts, cb) ->
    cc = @to_cryptocurrency opts
    msg = [ BTC, cc.type, colors.green(cc.address) ]
    log.lconsole "error", log.package().INFO, msg.join(' ')
    cb null

  #-----------

  insert_into_table : ({table, index, opts }) ->
    log.debug "+ Cryptocurrency::insert_into_table #{@sig_id()}"
    if not (id = @body()?.cryptocurrency?.address)?
      log.warn "Missing Cryptocurrency address"
      log.debug "Full JSON in signature:"
      log.debug @payload_json_str()
    else if not ([err,ret] = bitcoyne.address.check(id, { version : ACCTYPES}))?
      log.error "Error in checking cryptocurrency address: #{id}"
    else if err?
      log.warn "Error in cryptocurrency address: #{err.message}"
    else
      path = [ @sig_type(), ret.version ]
      # if we want to see revoked signatures, we have to have multiple entries for
      # bitcoins, so we further index on seqno
      path.push @seqno() if opts?.show_revoked
      table.insert_path path, @
    log.debug "- Cryptocurrency::insert_into_table #{@sig_id()}"

##=======================================================================

class Revoke extends Link

  insert_into_table : ({index}) ->
    log.debug "+ Revoke::insert_into_table"
    log.debug "- Revoke::insert_into_table"

##=======================================================================

class Untrack extends Link

  insert_into_table : ({table, index, opts}) ->
    log.debug "+ Untrack::insert_into_table"
    if not (id = @body()?.untrack?.id)? then log.warn "Mssing untrack in signature: #{@payload_json_str()}"
    else if not (link = table.get(ST.TRACK)?.get(id))? then log.debug "Unexpected untrack of #{id} in signature chain"
    else if not (link.is_leaf()) and not opts?.show_revoked then log.warn "Unexpected multi-follow"
    else
      links = if link.is_leaf() then [ link ]
      else link.flatten()
      for link in links
        if link.is_revoked() then log.debug "| Tracking was already revoked for #{id} (ignoring untrack)"
        else link.revoke()
    log.debug "- Untrack::insert_into_table"

##=======================================================================

# We can either have a link as an element the links table, or a LinkCollection,
# which we need in the case of HTTP and DNS proofs.
exports.LinkTable = class LinkTable
  constructor : (@table = {}) ->

  insert : (key, value) -> @table[key] = value

  insert_path : (path, value) ->
    d = @
    for k in path[0...-1]
      unless (v = d.get(k))?
        v = new LinkTable()
        d.insert k, v
      d = v
    d.insert path[-1...][0], value

  get : (key) -> @table[key]
  keys : () -> Object.keys @table

  get_path : (path) ->
    v = @
    (v = v.get(p) for p in path when v?)
    return v

  remove : (key) -> delete @table[key]

  to_dict : () -> @table

  is_leaf : () -> false

  walk : ({fn}) ->
    for k,v of @table
      v.walk { fn, parent : @, key : k}

  flatten : () ->
    out = []
    fn = ({key, value, parent}) -> out.push value
    @walk { fn }
    return out

  prune : (prune_condition) ->
    fn = ({key, value, parent}) ->
      parent.remove(key) if prune_condition(value)
    @walk { fn }

  select : (keys) ->
    out = new LinkTable
    for k in keys
      out.insert k, @get(k)
    return out

##=======================================================================
