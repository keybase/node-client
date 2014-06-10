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
{merkle_client} = require './merkle_client'
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
  is_self_sig : () -> @sig_type() in [ ST.SELF_SIG, ST.REMOTE_PROOF, ST.TRACK ]
  self_signer : () -> @payload_json()?.body?.key?.username
  proof_service_object : () -> @payload_json()?.body?.service
  remote_username : () -> @proof_service_object()?.username
  sig_type : () -> @obj.sig_type
  proof_type : () -> @obj.proof_type
  proof_state : () -> @obj.proof_state
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

  get_sub_id : () -> 
    scrapemod.alloc_stub(@proof_type())?.get_sub_id(@proof_service_object())

  #--------------------

  to_cryptocurrency : (opts) -> @body()?.cryptocurrency

  #--------------------

  to_list_display : (opts) ->
    name = scrapemod.alloc_stub(@proof_type())?.to_list_display(@proof_service_object())
    if opts?.with_sig_ids or opts?.with_proof_states?
      { name, sig_id : @sig_id(), proof_state : @proof_state() }
    else name

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

  # XXX maybe also refresh the state flag from the server?
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
      if not err? and (row = body?.row)? and (u = row.api_url)?
        log.debug "| Refreshed with api_url -> #{u}"
        @obj.api_url = u
        @obj.human_url = row.human_url
        await @store defer err
    log.debug "- refresh_link"
    cb err

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

  verify_sig : ({which, pubkey}, cb) ->
    pubkey.verify_sig { which, sig : @sig(), payload: @payload_json_str() }, cb

  #-----------

  display_cryptocurrency : (opts, cb) ->
    cc = @to_cryptocurrency opts
    msg = [ BTC, cc.type, colors.green(cc.address), "(#{colors.italic('unverified')})" ]
    log.lconsole "error", log.package().INFO, msg.join(' ')
    cb null

  #-----------

  check_remote_proof : ({skip, pubkey, type, warnings, assertions}, cb) ->

    username = pubkey.username()

    esc = make_esc cb, "SigChain::Link::check_remote_proof'"

    if not (type_s = proofs.proof_type_to_string[type])?
      err = new E.VerifyError "Unknown proof type (#{type}) found; consider a `keybase update`"
      await athrow err, esc defer()

    log.debug "+ #{username}: checking remote #{type_s} proof"

    assert = assertions?.found type_s

    await @verify_sig { which : "#{username}@#{type_s}", pubkey }, esc defer()

    assert?.set_payload @payload_json()

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

class SelfSig extends Link

#------------

class RemoteProof extends Link

#------------

class Track extends Link

#------------

class Cryptocurrency extends Link

#------------

class Revoke extends Link

#------------

class Untrack extends Link

##=======================================================================

exports.alloc = (obj) ->

##=======================================================================
