
db = require './db'
req = require './req'
log = require './log'
{constants} = require './constants'
{SHA256} = require './keyutils'
{E} = require './err'
{format_fingerprint,Warnings,asyncify} = require('pgp-utils').util
{make_esc} = require 'iced-error'
ST = constants.signature_types
{date_to_unix,make_email} = require './util'
proofs = require 'keybase-proofs'
cheerio = require 'cheerio'
request = require 'request'
colors = require 'colors'
deq = require 'deep-equal'
util = require 'util'
{env} = require './env'

##=======================================================================

strip = (x) -> x.replace(/\s+/g, '')

CHECK = "\u2714"
BAD_X = "\u2716"

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
  is_self_sig : () -> @sig_type() in [ ST.SELF_SIG, ST.REMOTE_PROOF, ST.TRACK ]
  self_signer : () -> @payload_json()?.body?.key?.username
  remote_username : () -> @payload_json()?.body?.service?.username
  sig_type : () -> @obj.sig_type
  proof_type : () -> @obj.proof_type
  sig_id : () -> @obj.sig_id
  api_url : () -> @obj.api_url
  human_url : () -> @obj.human_url
  proof_text_check : () -> @obj.proof_text_check
  remote_id : () -> @obj.remote_id
  body : () -> @payload_json()?.body
  ctime : () -> date_to_unix @obj.ctime
  revoke : () -> @_revoked = true
  is_revoked : () -> @_revoked

  #--------------------

  to_table_obj : () -> 
    ret = @body().track
    ret.ctime = @ctime()
    return ret

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

  refresh : (cb) ->
    log.debug "+ refresh link"
    if (@sig_type() is ST.REMOTE_PROOF) and not @api_url()?
      log.debug "| Proof_id = #{@obj.proof_id}"
      arg = 
        endpoint : "sig/remote_proof"
        args :
          proof_id : @obj.proof_id
      log.debug "| request proof refresh for id=#{@obj.proof_id}"
      await req.get arg, defer err, body
      if not err? and (row = u.body?.row)? and (u = row.api_url)?
        log.debug "| Refreshed with api_url -> #{u}"
        @obj.api_url = u
        @obj.human_url = row.human_url
        await @store defer err
    log.debug "- refresh_link"
    cb err

  #--------------------

  @load : (id, cb) ->
    ret = null
    await db.get { type : Link.ID_TYPE, key : id }, defer err, obj
    if err? then # noop
    else if obj?
      ret = new Link { id, obj }
      if (err = ret.verify())? then ret = null
    cb err, ret

  #--------------------

  verify_sig : ({which, pubkey}, cb) ->
    pubkey.verify_sig { which, sig : @sig(), payload: @payload_json_str() }, cb

  #-----------

  alloc_scraper : (type, cb) ->
    PT = proofs.constants.proof_types
    err = scraper = null
    klass = switch type
      when PT.twitter then proofs.TwitterScraper
      when PT.github  then proofs.GithubScraper
      else null
    if not klass
      err = new E.ScrapeError "cannot allocate scraper of type #{type}"
    else
      scraper = new klass { libs : { cheerio, request, log } }
    cb err, scraper

  #-----------

  check_remote_proof : ({skip, pubkey, type, warnings, assertions}, cb) ->

    username = pubkey.username()

    esc = make_esc cb, "SigChain::Link::check_remote_proof'"

    if not (type_s = proofs.proof_type_to_string[type])?
      err = new E.VerifyError "No remote proof type for #{type}"
      await athrow err, esc defer()

    log.debug "+ #{username}: checking remote #{type_s} proof"

    assert = assertions?.found type_s

    await @verify_sig { which : "#{username}@#{type_s}", pubkey }, esc defer()
    if not (remote_username = @remote_username())?
      err = new E.VerifyError "no remote username found in proof"
      await athrow err, esc defer()

    assert?.set_remote_username remote_username

    if not skip and not @api_url()
      await @refresh defer e2
      if e2?
        log.warn "Error fetching URL for proof: #{e2.message}"

    log.debug "| remote username is #{remote_username}"
    if skip
      rc = proofs.constants.v_codes.OK
    else if not @api_url()
      rc = proofs.constants.v_codes.NOT_FOUND
    else
      await @alloc_scraper type, esc defer scraper
      log.debug "+ Calling into scraper -> #{remote_username}@#{type_s} -> #{@api_url()}"
      await scraper.validate {
        username : remote_username,
        api_url : @api_url(),
        signature : @sig(),
        proof_text_check : @proof_text_check()
        remote_id : (""+@remote_id())
      }, esc defer rc
      log.debug "- Called scraper -> #{rc}"

    ok = false
    if rc isnt proofs.constants.v_codes.OK
      warnings.push new E.RemoteCheckError "Remote check failed (code: #{rc})"
      @obj.proof_state = rc
    else
      ok = true
      log.debug "| proof checked out"
    msg = [
       (if ok then CHECK else BAD_X) 
       ('"' + ((if ok then colors.green else colors.red) remote_username) + '"')
       "on"
       (type_s + ":")
       @human_url()
    ]
    msg.push ("(you've recently OK'ed these proofs)") if skip
    msg.push "(failed with code #{rc})" if not ok
    log.console.error msg.join(' ')
    log.debug "- #{username}: checked remote #{type_s} proof"

    assert?.success @human_url()

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


##=======================================================================

exports.SigChain = class SigChain 

  constructor : (@uid, @_links = []) ->
    @_lookup = {}
    @_index_links @_links

  #-----------

  _index_links : (list) -> 
    for l in list
      @_lookup[l.id] = l

  #-----------

  lookup : (id) -> @_lookup[id]

  #-----------

  @load : (uid, curr, cb) ->
    log.debug "+ #{uid}: load signature chain"
    links = []
    err = null
    ret = null
    while curr and not err?
      log.debug "| #{uid}: Loading link #{curr}"
      await Link.load curr, defer err, link
      if err?
        log.error "Couldn't find link: #{last}"
        log.debug "| -> error"
      else if link?
        links.push link
        curr = link.prev()
        log.debug "| -> found link and previous; prev=#{curr}"
      else 
        log.debug "| -> reached the chain end"
        curr = null
    unless err?
      ret = new SigChain uid, links.reverse()
      if (err = ret.check_chain true)? then ret = null
    log.debug "- #{uid}: loaded signature chain"
    cb err, ret

  #-----------

  last_seqno : () -> if (l = @last())? then l.seqno() else null

  #-----------

  check_chain : (first, links) ->
    links or= @_links
    prev = null
    i =  0
    for link in links 
      if (prev? and (prev isnt link.prev())) or (not prev? and first and link.prev())
        return new E.CorruptionError "Bad chain link in #{link.seqno()}: #{prev} != #{link.prev()}"
      prev = link.id
    return null

  #-----------

  _update : (cb) ->
    esc = make_esc cb, "_update"
    args = { @uid, low : (@last_seqno() + 1) }
    await req.get { endpoint : "sig/get", args }, esc defer body
    new_links = [] 
    did_update = false
    for obj in body.sigs
      link = new Link { obj }
      await asyncify link.verify(), esc defer()
      new_links.push link
      did_update = true
    await asyncify (@check_chain (@_links.length is 0), new_links), esc defer()
    await asyncify (@check_chain false, (@_links[-1...].concat new_links[0..0])), esc defer()
    @_links = @_links.concat new_links
    @_new_links = new_links
    @_index_links new_links
    cb null, did_update

  #-----------

  store : (cb) ->
    err = null
    if @_new_links?.length
      log.debug "+ writing dirty signature chain"
      for link in @_new_links when not err?
        await link.store defer err
      log.debug "- wrote signature chain"
    cb err

  #-----------

  update : (remote_seqno, cb) ->
    err = null
    did_update = false
    if not (a = remote_seqno)? or a > (b = @last_seqno())
      log.debug "| sigchain update: #{a} vs. #{b}"
      await @_update defer err, did_update
      if remote_seqno? and ((a = remote_seqno) isnt (b = @last_seqno()))
        err = new E.CorruptionError "failed to appropriately update chain: #{a} != #{b}"
    cb err, did_update

  #-----------

  last : () ->
    if @_links?.length then @_links[-1...][0] else null

  #-----------

  # Given that I signed hash id `id`, is this still a fresh track?
  # The answer is yes if I signed the last link in the chain, or links
  # further back in the chain so long there were only TRACK and UNTRACK
  # signatures in between.
  is_track_fresh : (id) ->
    for l in @_links by -1
      if l.id is id then return true
      else if not (l.sig_type() in [ ST.TRACK, ST.UNTRACK ]) then return false
    return false

  #-----------

  # Limit the chain to only those links signed by the key used in the last link
  _limit : () ->
    c = []
    log.debug "| input chain with #{n = @_links.length} link#{if n isnt 1 then 's' else ''}"
    for i in [(@_links.length-1)..0]
      if (l = @_links[i]).fingerprint() is @fingerprint then c.push l
      else break
    c = c.reverse()
    if c.length isnt @_links.length
      log.debug "| Limited to #{n = c.length} link#{if n isnt 1 then 's' else ''}"
    @_links = c

 #--------------

  _verify_sig : (cb) ->
    err = null
    await l.verify_sig { which : @username, @pubkey }, defer err if (l = @last())?
    cb err

  #-----------

  _verify_userid : (cb) ->
    esc = make_esc cb, "_verify_userid"

    log.debug "+ _verify_userid for #{@username}"
    found = false

    # first try to see if the username is baked into the key, and be happy with that
    await @pubkey.read_uids_from_key esc defer uids
    found = (email for {email} in uids).indexOf(make_email @username) >= 0

    # Search for an explicit self-signature of this key
    if not found and (v = @table?[ST.SELF_SIG])?
      for link in v
        if link.self_signer() is @username 
          found = true
          break

    # Search for a freeloader in an otherwise useful signature
    if not found
      for type in [ ST.REMOTE_PROOF, ST.TRACK ] 
        if (d = @table?[type])
          for k,link of d 
            if link.self_signer() is @username 
              found = true
              break
          break if found

    if not err? and not found
      msg = if @username is env().get_username() 
        "You haven't signed your own key! Try `keybase revoke` and then `keybase push`"
      else "user '#{@username}' hasn't signed their own key"
      err = new E.VerifyError msg

    log.debug "- _verify_userid for #{@username} -> #{err}"
    cb err

  #-----------

  _compress : () ->

    log.debug "+ compressing signature chain"

    MAKE = (d,k,def) -> if (out = d[k]) then out else d[k] = out = def

    out = {}
    index = {}

    for link in @_links when link.fingerprint() is @fingerprint
      lt = link.sig_type()
      sig_id = link.sig_id()
      pjs = link.payload_json_str()
      body = link.payload_json()?.body
      index[link.sig_id()] = link

      switch lt
        when ST.SELF_SIG     then MAKE(out, lt,[]).push link
        when ST.REMOTE_PROOF then MAKE(out, lt, {})[link.proof_type()] = link

        when ST.TRACK 
          if not (id = body?.track?.id)? 
            log.warn "Missing track in signature"
            log.debug "Full JSON in signature:"
            log.debug pjs
          else MAKE(out,lt,{})[id] = link

        when ST.REVOKE
          if not (sig_id = body?.revoke?.sig_id)
            log.warn "Cannot find revoke sig_id in signature: #{pjs}"
          else if not (link = index[sig_id])?
            log.warn "Cannot revoke signature #{sig_id} since we haven't seen it"
          else if link.is_revoked()
            log.info "Signature is already revoked: #{sig_id}"
          else
            link.revoke()

        when ST.UNTRACK
          if not (id = body?.untrack?.id)? then log.warn "Mssing untrack in signature: #{pjs}"
          else if not (link = out[ST.TRACK]?[id])? then log.warn "Unexpected untrack of #{id} in signature chain"
          else if link.is_revoked() then log.debug "| Tracking was already revoked for #{id} (ignoring untrack)"
          else link.revoke()

        else
          log.warn "unknown public sig type: #{lt}"

    prune = (d) ->
      for k,v of d
        if not (v instanceof Link) then prune v
        else if v.is_revoked() then delete d[k]

    # remove all revoked signatures in one final pass
    prune out

    log.debug "- signature chain compressed"
    @table = out

  #-----------

  remote_proofs_to_track_obj : () ->
    if (d = @table?[ST.REMOTE_PROOF])?
      (link.remote_proof_to_track_obj() for key,link of d when not link.is_revoked())
    else []

  #-----------

  get_track_obj : (uid) -> @table[ST.TRACK]?[uid]?.to_table_obj()

  #-----------

  verify_sig : ({key}, cb) ->
    esc = make_esc cb, "SigChain::verify_sig"
    @username = username = key.username()
    @pubkey = key
    log.debug "+ #{username}: verifying sig"
    if (@fingerprint = @last()?.fingerprint())?
      @_limit()
      @_compress()
      await @_verify_sig esc defer()
    else
      log.debug "| Skipped since no fingerprint found in key"
    await @_verify_userid esc defer()
    log.debug "- #{username}: verified sig"
    cb null

  #-----------

  list_remote_proofs : () ->
    out = null
    if @table? and (tab = @table[ST.REMOTE_PROOF])?
      for type,link of tab
        type = proofs.proof_type_to_string[parseInt(type)]
        out or= {}
        out[type] = link.remote_username()

    return out

  #-----------

  check_remote_proofs : ({skip, pubkey, assertions}, cb) ->
    esc = make_esc cb, "SigChain::check_remote_proofs"
    log.debug "+ #{pubkey.username()}: checking remote proofs (skip=#{skip})"
    warnings = new Warnings()

    msg = CHECK + " " + colors.green("public key fingerprint: #{format_fingerprint pubkey.fingerprint()}")
    log.console.error msg
    n = 0
    if (tab = @table?[ST.REMOTE_PROOF])?
      log.debug "| Loaded table with #{Object.keys(tab).length} keys"
      for type,link of tab
        type = parseInt(type) # we expect it to be an int, not a dict key
        await link.check_remote_proof { skip, pubkey, type, warnings, assertions }, esc defer()
        n++
    else
      log.debug "| No remote proofs found"
    log.debug "- #{pubkey.username()}: checked remote proofs"
    cb null, warnings, n

##=======================================================================

