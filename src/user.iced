
req = require './req'
{gpg} = require './gpg'
db = require './db'
{constants} = require './constants'
{make_esc} = require 'iced-error'
{E} = require './err'
deepeq = require 'deep-equal'
{SigChain} = require './sigchain'
{BufferOutStream,grep} = require './stream'
{parse} = require('pgp-utils').userid

##=======================================================================

strip = (x) -> x.replace(/\s+/g, '')

##=======================================================================

exports.make_email = make_email = (un) -> un + "@" + constants.canonical_host 

##=======================================================================

exports.User = class User 

  #--------------

  @FIELDS : [ "basics", "public_keys", "id", "sigs" ]

  #--------------

  constructor : (args) ->
    for k in User.FIELDS
      @[k] = args[k]
    @_dirty = false
    @sig_chain = null

  #--------------

  to_obj : () -> 
    out = {}
    for k in User.FIELDS
      out[k] = @[k]
    return out

  #--------------

  name : () -> { type : constants.lookups.username, name : @basics.username }

  #--------------

  store : (force_store, cb) ->
    err = null
    if force_store or @_dirty
      await db.put { key : @id, value : @to_obj(), name : @name() }, defer err
    if @sig_chain? and not err?
      await @sig_chain.store defer err
    cb err

  #--------------

  update_fields : (remote) ->
    for k in User.FIELDS
      @update_field remote, k
    true

  #--------------

  update_field : (remote, which) ->
    if not (deepeq(@[which], remote[which]))
      @[which] = remote[which]
      @_dirty = true

  #--------------

  load_sig_chain_from_storage : (cb) ->
    err = null
    @last_sig = @sigs?.last or { seqno : 0 }
    if (ph = @last_sig.payload_hash)?
      await SigChain.load @id, ph, defer err, @sig_chain
    else
      @sig_chain = new SigChain @id
    cb err

  #--------------

  load_full_sig_chain : (cb) ->
    sc = new SigChain @id
    await sc.update null, defer err
    @sig_chain = sc unless err?
    cb err

  #--------------

  update_sig_chain : (remote, cb) ->
    await @sig_chain.update remote?.sigs?.last?.seqno, defer err
    cb err

  #--------------

  update_with : (remote, cb) ->
    err = null

    a = @basics?.id_version
    b = remote?.basics?.id_version

    if not b? or a > b
      err = new E.VersionRollbackError "Server version-rollback suspected: Local #{a} > #{b}"
    else if not a? or a < b
      @update_fields remote
    else if a isnt b
      err = new E.CorruptionError "Bad ids on user objects: #{a.id} != #{b.id}"

    if not err?
      await @update_sig_chain remote, defer err

    cb err

  #--------------

  @load : ({username}, cb) ->
    esc = make_esc cb, "User::load"
    await User.load_from_server {username}, esc defer remote
    await User.load_from_storage {username}, esc defer local
    changed = true
    force_store = false
    if local?
      await local.update_with remote, esc defer()
    else if remote?
      local = remote
      await local.load_full_sig_chain esc defer()
      force_store = true
    else
      err = new E.UserNotFoundError "User #{username} wasn't found"
    if not err?
      await local.store force_store, esc defer()
    cb err, local

  #--------------

  @load_from_server : ({username}, cb) ->
    args = 
      endpoint : "user/lookup"
      args : {username }
    await req.get args, defer err, body
    ret = null
    unless err?
      ret = new User body.them
    cb err, ret

  #--------------

  @load_from_storage : ({username}, cb) ->
    ret = null
    await db.lookup { type : constants.lookups.username, name: username }, defer err, row
    if not err? and row?
      ret = new User row.value
      await ret.load_sig_chain_from_storage defer err
      if err?
        ret = null
    cb err, ret

  #--------------

  query_key : ({secret}, cb) ->
    if (@fingerprint = @public_keys?.primary?.key_fingerprint?.toUpperCase())?
      args = [ "-" + (if secret then 'K' else 'k'), @fingerprint ]
      await gpg { args, quiet : true }, defer err, out
      if err?
        err = new E.NoLocalKeyError "the user #{@username()} doesn't have a local key"
    else
      err = new E.NoRemoteKeyError "the user #{@username()} doesn't have a remote key"
    cb err

  #--------------

  check_public_key : (cb) ->
    await @query_key { secret : false }, defer err
    cb err

  #--------------

  username : () -> @basics.username

  #--------------

  import_public_key : (cb) ->
    found = false
    await @query_key { secret : false }, defer err
    if not err? then found = true
    else if not (err instanceof E.NoLocalKeyError)? then # noops
    else if not (data = @public_keys?.primary?.bundle)?
      err = new E.ImportError "no public key found for #{@username()}"
    else
      uid = @id
      state = constants.import_state.TEMPORARY
      await db.log_key_import { uid, state, @fingerprint }, defer err
      unless err?
        args = [ "--import" ]
        await gpg { args, stdin : data }, defer err, out
        if err?
          err = new E.ImportError "#{@username()}: key import error: {err.message}"
    cb err, found

  #--------------

  verify_sig : (cb) ->
    err = null
    if (last = @sig_chain.last())?
      args = [ "--decrypt" ]
      stderr = new BufferOutStream()
      await gpg { args, stdin : last.sig(), stderr }, defer err, out
      if err?
        err = new E.VerifyError "#{@username()}: failed to verify signature"
      else if not (m = stderr.data().toString('utf8').match(/Primary key fingerprint: (.*)/))?
        err = new E.VerifyError "#{@username()}: can't parse PGP output in verify signature"
      else if ((a = strip(m[1]).toLowerCase()) isnt (b = last.fingerprint()))
        err = new E.VerifyError "#{@username()}: bad key: #{a} != #{b}"
      else if ((a = out.toString('utf8')) isnt (b = last.payload_json_str()))
        err = new E.VerifyError "#{@username()}: payload was wrong: #{a} != #{b}"

      # now we can say that we have a valid last fingerprint....
      unless err?
        @_fingerprint = last.fingerprint()
    cb err

  #--------------

  read_uids_from_key : (cb) ->
    args = [ "-k", @_fingerprint ]
    await gpg { args, quiet : true } , defer err, out
    unless err?
      pattern = /^uid\s+(.*)$/
      lines = grep { buffer : out, pattern }
      out = (u for line in lines when (m = line.match pattern)? and (u = parse m[1])?)
    cb err, out

  #--------------

  verify_userid : (cb) ->
    await @read_uids_from_key defer err, uids
    found = null
    unless err?
      search_for = make_email @username()
      emails = (email for {email} in uids)
      found = emails.indexOf(search_for) >= 0
    if not err? and not found
      links = @sig_chain.limit()
      for link in links when link.is_self_sig()
        if link.self_signer() is @username()
          found = true
          break
    if not err? and not found
      err = new E.VerifyError "could not find self signature of username '#{@username()}'"
    cb err

  #--------------

  verify_signed_key : (cb) ->
    cb new E.NotImplementedError "not implemented"

  #--------------

  compress : (cb) ->
    err = null
    await @sig_chain.compress defer err if @sig_chain
    cb err

##=======================================================================

