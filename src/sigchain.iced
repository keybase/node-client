
db = require './db'
req = require './req'
log = require './log'
{constants} = require './constants'
{SHA256} = require './keyutils'
{E} = require './err'
{Warnings,asyncify} = require('pgp-utils').util
{make_esc} = require 'iced-error'
ST = constants.signature_types
{BufferOutStream} = require './stream'
{gpg,read_uids_from_key} = require './gpg'
{make_email} = require './util'
proofs = require 'keybase-proofs'
cheerio = require 'cheerio'
request = require 'request'

##=======================================================================

strip = (x) -> x.replace(/\s+/g, '')

##=======================================================================

exports.Link = class Link

  @ID_TYPE : constants.ids.sig_chain_link

  #--------------------
  
  constructor : ({@id,@obj}) ->
    @id or= @obj.payload_hash

  #--------------------

  prev : () -> @obj.prev
  seqno : () -> @obj.seqno
  sig : () -> @obj.sig
  payload_json_str : () -> @obj.payload_json
  fingerprint : () -> @obj.fingerprint.toLowerCase()
  is_self_sig : () -> @sig_type() in [ ST.SELF_SIG, ST.REMOTE_PROOF, ST.TRACK ]
  self_signer : () -> @payload_json()?.body?.key?.username
  sig_type : () -> @obj.sig_type
  proof_type : () -> @obj.proof_type
  sig_id : () -> @obj.sig_id
  api_url : () -> @obj.api_url
  proof_text_check : () -> @obj.proof_text_check
  remote_id : () -> @obj.remote_id
 
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
    await db.put { type : Link.ID_TYPE, key : @id, value : @obj }, defer err
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

  verify_sig : ({which}, cb) ->
    args = [ "--decrypt" ]
    stderr = new BufferOutStream()
    await gpg { args, stdin : @sig(), stderr }, defer err, out
    if err?
      err = new E.VerifyError "#{which}: failed to verify signature"
    else if not (m = stderr.data().toString('utf8').match(/Primary key fingerprint: (.*)/))?
      err = new E.VerifyError "#{which}: can't parse PGP output in verify signature"
    else if ((a = strip(m[1]).toLowerCase()) isnt (b = @fingerprint()))
      err = new E.VerifyError "#{which}: bad key: #{a} != #{b}"
    else if ((a = out.toString('utf8')) isnt (b = @payload_json_str()))
      err = new E.VerifyError "#{which}: payload was wrong: #{a} != #{b}"
    cb err

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

  check_remote_proof : ({username, type, warnings}, cb) ->
    esc = make_esc cb, "SigChain::Link::check_remote_proof'"
    if not (type_s = proofs.proof_type_to_string[type])?
      err = new E.VerifyError "No remove proof type for #{type}"
    else
      err = null
      log.debug "+ #{username}: checking remote #{type_s} proof"
      await @verify_sig { which : "#{username}@#{type_s}" }, esc defer()
      if not (remote_username = @payload_json()?.body?.service?.username)?
        err = new E.VerifyError "no remote username found in proof"
      else
        log.debug "| remote username is #{remote_username}"
        await @alloc_scraper type, esc defer scraper
        await scraper.validate {
          username : remote_username,
          api_url : @api_url(),
          signature : @sig(),
          proof_text_check : @proof_text_check()
          remote_id : (""+@remote_id())
        }, esc defer rc
        if rc isnt proofs.constants.v_codes.OK
          err = new E.RemoteCheckError "Remote check failed (code: #{rc})"
        else
          log.debug "| proof checked out"
      log.debug "- #{username}: checked remote #{type_s} proof"
    cb err

##=======================================================================

exports.SigChain = class SigChain 

  constructor : (@uid, @_links = []) ->

  #-----------

  @load : (uid, curr, cb) ->
    log.debug "+ #{uid}: load signature chain"
    links = []
    err = null
    ret = null
    while curr and not err?
      await Link.load curr, defer err, link
      if err?
        log.error "Couldn't find link: #{last}"
      else if link?
        links.push link
        curr = link.prev()
      else 
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
    for obj in body.sigs
      link = new Link { obj }
      await asyncify link.verify(), esc defer()
      new_links.push link
    await asyncify (@check_chain (@_links.length is 0), new_links), esc defer()
    await asyncify (@check_chain false, (@_links[-1...].concat new_links[0..0])), esc defer()
    @_links = @_links.concat new_links
    @_new_links = new_links
    cb null

  #-----------

  compress : (cb) ->
    cb new E.NotImplementedError "not implemented yet"

  #-----------

  store : (cb) ->
    err = null
    if @_new_links?
      log.debug "+ writing dirty signature chain"
      for link in @_new_links when not err?
        await link.store defer err
      log.debug "- wrote signature chain"
    cb err

  #-----------

  update : (remote_seqno, cb) ->
    err = null
    if not (a = remote_seqno)? or a > (b = @last_seqno())
      log.debug "| sigchain update: #{a} vs. #{b}"
      await @_update defer err
      if remote_seqno? and ((a = remote_seqno) isnt (b = @last_seqno()))
        err = new E.CorruptionError "failed to appropriately update chain: #{a} != #{b}"
    cb err

  #-----------

  last : () ->
    if @_links?.length then @_links[-1...][0] else null

  #-----------

  # Limit the chain to only those links signed by the key used in the last link
  _limit : () ->
    c = []
    for i in [(@_links.length-1)..0]
      if (l = @_links[i]).fingerprint() is @fingerprint then c.push l
      else break
    c = c.reverse()
    @_links = c

 #--------------

  _verify_sig : (cb) ->
    err = null
    await l.verify_sig { which : @username }, defer err if (l = @last())?
    cb err

  #-----------

  _verify_userid : (cb) ->
    esc = make_esc cb, "_verify_userid"

    # first try to see if the username is baked into the key, and be happy with that
    await read_uids_from_key { @fingerprint}, esc defer uids
    found = (email for {email} in uids).indexOf(make_email @username) >= 0
    found = false

    # Search for an explicit self-signature of this key
    if not found and (v = @table[ST.SELF_SIG])?
      for link in v
        if link.self_signer() is @username 
          found = true
          break

    # Search for a freeloader in an otherwise useful signature
    if not found
      for type in [ ST.REMOTE_PROOF, ST.TRACK ] 
        if (d = @table[type])
          for k,link of d
            if link.self_signer() is @username 
              found = true
              break
          break if found

    if not err? and not found
      err = new E.VerifyError "could not find self signature of username '#{@username}'"
    cb err

  #-----------

  _compress : () ->

    MAKE = (d,k,def) -> if (out = d[k]) then out else d[k] = out = def

    out = {}
    index = {}

    for link in @_links when link.fingerprint() is @fingerprint
      lt = link.sig_type()
      sig_id = link.sig_id()
      pjs = link.payload_json_str()
      body = link.payload_json()?.body
      index[link.sig_id()] = lt

      switch lt
        when ST.SELF_SIG then MAKE(out, lt,[]).push link
        when ST.REMOTE_PROOF then MAKE(out, lt, {})[link.proof_type()] = link

        when ST.TRACK 
          if not (id = body?.track?.id) then log.warn "Missing track in signature: #{pjs}"
          else MAKE(out,lt,{})[id] = link

        when ST.REVOKE
          if not (sig_id = body?.revoke?.sig_id)
            log.warn "Cannot find revoke sig_id in signature: #{pjs}"
          else if not (cat = index[sig_id])? or not (sig = out[cat])?
            log.warn "Cannot revoke signature #{sig_id} since we haven't seen it"
          else if not sig.sig_id() is sig_id
            log.warn "Cannot revoke signature #{sig_id} since it's been superseded"
          else
            delete out[cat]

        when ST.UNFOLLOW
          if not (id = body?.tracl?.id?) then log.warn "Mssing untrack in signature: #{pjs}"
          else if not (out[ST.TRACK]?[id]?) then log.warn "Not tracking #{id} to begin with"
          else delete out[ST.TRACK][id]

    @table = out

  #-----------

  verify_sig : ({username}, cb) ->
    esc = make_esc cb, "SigChain::verify_sig"
    @username = username
    if (@fingerprint = @last()?.fingerprint())?
      @_limit()
      @_compress()
      await @_verify_sig esc defer()
      await @_verify_userid esc defer()
    cb null

  #-----------

  check_remote_proofs : ({username}, cb) ->
    esc = make_esc cb, "SigChain::check_remote_proofs"
    log.debug "+ #{username}: checking remote proofs"
    warnings = new Warnings()
    if (tab = @table[ST.REMOTE_PROOF])?
      for type,link of tab
        type = parseInt(type) # we expect it to be an int, not a dict key
        await link.check_remote_proof { username, type, warnings }, esc defer()
    log.debug "- #{username}: checked remote proofs"
    cb null

##=======================================================================

