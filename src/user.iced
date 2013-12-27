
req = require './req'
{gpg} = require './gpg'
db = require './db'
{constants} = require './constants'
{make_esc} = require 'iced-error'
{E} = require './err'
deepeq = require 'deep-equal'
{SigChain} = require './sigchain'
log = require './log'

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
    un = @username()
    if force_store or @_dirty
      log.debug "+ #{un}: storing user to local DB"
      await db.put { key : @id, value : @to_obj(), name : @name() }, defer err
      log.debug "+ #{un}: storing user to local DB"
    if @sig_chain? and not err?
      log.debug "+ #{un}: storing signature chain"
      await @sig_chain.store defer err
      log.debug "- #{un}: stored signature chain"
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
    log.debug "+ load sig chain from local storage"
    @last_sig = @sigs?.last or { seqno : 0 }
    if (ph = @last_sig.payload_hash)?
      log.debug "| loading sig chain w/ payload hash #{ph}"
      await SigChain.load @id, ph, defer err, @sig_chain
    else
      @sig_chain = new SigChain @id
    log.debug "- loaded sig chain from local storage"
    cb err

  #--------------

  load_full_sig_chain : (cb) ->
    log.debug "+ load full sig chain"
    sc = new SigChain @id
    await sc.update null, defer err
    @sig_chain = sc unless err?
    log.debug "| loaded full sig chain"
    cb err

  #--------------

  update_sig_chain : (remote, cb) ->
    seqno = remote?.sigs?.last?.seqno
    log.debug "+ update sig chain; seqno=#{seqno}"
    await @sig_chain.update seqno, defer err
    log.debug "- updated sig chain"
    cb err

  #--------------

  update_with : (remote, cb) ->
    err = null
    log.debug "+ updating local user w/ remote"

    a = @basics?.id_version
    b = remote?.basics?.id_version

    if not b? or a > b
      err = new E.VersionRollbackError "Server version-rollback suspected: Local #{a} > #{b}"
    else if not a? or a < b
      log.debug "| version update needed: #{a} vs. #{b}"
      @update_fields remote
    else if a isnt b
      err = new E.CorruptionError "Bad ids on user objects: #{a.id} != #{b.id}"

    if not err?
      await @update_sig_chain remote, defer err

    log.debug "- finished update"

    cb err

  #--------------

  @load : ({username}, cb) ->
    esc = make_esc cb, "User::load"
    log.debug "+ #{username}: load user"
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
    log.debug "- #{username}: loaded user"
    cb err, local

  #--------------

  @load_from_server : ({username}, cb) ->
    log.debug "+ #{username}: load user from server"
    args = 
      endpoint : "user/lookup"
      args : {username }
    await req.get args, defer err, body
    ret = null
    unless err?
      ret = new User body.them
    log.debug "- #{username}: loaded user from server"
    cb err, ret

  #--------------

  @load_from_storage : ({username}, cb) ->
    log.debug "+ #{username}: load user from local storage"
    ret = null
    await db.lookup { type : constants.lookups.username, name: username }, defer err, row
    if not err? and row?
      ret = new User row.value
      await ret.load_sig_chain_from_storage defer err
      if err?
        ret = null
    log.debug "- #{username}: loaded user from local storage"
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
    un = @username()
    log.debug "+ #{un}: checking public key"
    await @query_key { secret : false }, defer err
    log.debug "- #{un}: checked public key"
    cb err

  #--------------

  username : () -> @basics.username

  #--------------

  import_public_key : (cb) ->
    un = @username()
    log.debug "+ #{un}: import public key"
    uid = @id
    found = false
    await @query_key { secret : false }, defer err
    if not err? 
      log.debug "| found locally"
      await db.get_import_state { uid, @fingerprint }, defer err, state
      log.debug "| read state from DB as #{state}"
      found = (state isnt constants.import_state.TEMPORARY)
    else if not (err instanceof E.NoLocalKeyError)? then # noops
    else if not (data = @public_keys?.primary?.bundle)?
      err = new E.ImportError "no public key found for #{un}"
    else
      state = constants.import_state.TEMPORARY
      log.debug "| temporarily importing key to local GPG"
      await db.log_key_import { uid, state, @fingerprint }, defer err
      unless err?
        args = [ "--import" ]
        await gpg { args, stdin : data, quiet : true }, defer err, out
        if err?
          err = new E.ImportError "#{un}: key import error: {err.message}"
    log.debug "- #{un}: imported public key (found=#{found})"
    cb err, found

  #--------------

  remove_key : (cb) ->
    un = @username()
    uid = @id
    esc = make_esc cb, "SigChain::remove_key"
    log.debug "+ #{un}: remove temporarily imported public key"
    args = [ "--batch", "--delete-keys", @fingerprint ]
    state = constants.import_state.CANCELED
    await gpg { args }, esc defer()
    await db.log_key_import { uid, state, @fingerprint}, esc defer()
    log.debug "- #{un}: removed temporarily imported public key"
    cb null

  #--------------

  check_remote_proofs : (cb) ->
    await @sig_chain.check_remote_proofs { username : @username() }, defer err, warnings
    cb err, warnings

  #--------------

  # Also serves to compress the public signatures into a usable table.
  verify : (cb) ->
    await @sig_chain.verify_sig { username : @username() }, defer err
    cb err

  #--------------

  load_local_track : (uid, cb) ->
    await db.get { type : constants.ids.local_track, key : uid }, defer err, value
    cb err, value

  #--------------

  find_track : (them, cb) ->
    err = null
    tuid = them.id
    if not (track = @sig_chain?.get_track tuid)?
      await @load_local_track tuid, defer err, track
    cb err, track

##=======================================================================

