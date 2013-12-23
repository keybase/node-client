
db = require './db'
req = require './req'
log = require './log'
{constants} = require './constants'
{SHA256} = require './keyutils'
{E} = require './err'
{asyncify} = require('pgp-utils').util
{make_esc} = require 'iced-error'
ST = constants.signature_types
{BufferOutStream} = require './stream'
{gpg,read_uids_from_key} = require './gpg'
{make_email} = require './util'

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
  is_self_sig : () -> @obj.sig_type in [ ST.SELF_SIG, ST.REMOTE_PROOF, ST.TRACK ]
  self_signer : () -> @payload_json()?.body?.key?.username
 
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

  verify_sig : ({username}, cb) ->
    args = [ "--decrypt" ]
    stderr = new BufferOutStream()
    await gpg { args, stdin : @sig(), stderr }, defer err, out
    if err?
      err = new E.VerifyError "#{username}: failed to verify signature"
    else if not (m = stderr.data().toString('utf8').match(/Primary key fingerprint: (.*)/))?
      err = new E.VerifyError "#{username}: can't parse PGP output in verify signature"
    else if ((a = strip(m[1]).toLowerCase()) isnt (b = @fingerprint()))
      err = new E.VerifyError "#{username}: bad key: #{a} != #{b}"
    else if ((a = out.toString('utf8')) isnt (b = @payload_json_str()))
      err = new E.VerifyError "#{username}: payload was wrong: #{a} != #{b}"
    cb err

##=======================================================================

exports.SigChain = class SigChain 

  constructor : (@uid, @_links = []) ->

  #-----------

  @load : (uid, curr, cb) ->
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
      for link in @_new_links when not err?
        await link.store defer err
    cb err

  #-----------

  update : (remote_seqno, cb) ->
    err = null
    if not remote_seqno? or remote_seqno > @last_seqno()
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
    await l.verify_sig { @username }, defer err if (l = @last())?
    cb err

  #-----------

  _verify_userid : (cb) ->
    await read_uids_from_key { @fingerprint}, defer err, uids
    found = null
    unless err?
      search_for = make_email @username
      emails = (email for {email} in uids)
      found = emails.indexOf(search_for) >= 0
    if not err? and not found
      for link in @_links when link.is_self_sig()
        if link.self_signer() is @username
          found = true
          break
    if not err? and not found
      err = new E.VerifyError "could not find self signature of username '#{@username}'"
    cb err

  #-----------

  verify_sig : ({username}, cb) ->
    esc = make_esc cb, "SigChain.verify_sig"
    @username = username
    if (@fingerprint = @last()?.fingerprint())?
      @_limit()
      await @_verify_sig esc defer()
      await @_verify_userid esc defer()
    cb null

##=======================================================================

