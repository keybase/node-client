
db = require './db'
req = require './req'
log = require './log'
{constants} = require './constants'
{SHA256} = require './keyutils'
{E} = require './err'
{asyncify} = require('pgp-utils').util
{make_esc} = require 'iced-error'
ST = constants.signature_types

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
  limit : () ->
    unless @_limited_chain
      c = []
      if (fp = @last()?.fingerprint())?
        for i in [(@_links.length-1)..0]
          if (l = @_links[i]).fingerprint() is fp then c.push l
          else break
      c = c.reverse()
      @_limited_chain = c
    return @_limited_chain 

##=======================================================================

