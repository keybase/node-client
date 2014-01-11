req = require './req'
db = require './db'
{constants} = require './constants'
{make_esc} = require 'iced-error'
{GE,E} = require './err'
deepeq = require 'deep-equal'
{SigChain} = require './sigchain'
log = require './log'
{UntrackerProofGen,TrackerProofGen} = require './sigs'
{session} = require './session'
{env} = require './env'
{TrackWrapper} = require './trackwrapper'
{unix_time} = require('pgp-utils').util
{TmpKeyRing,load_key,master_ring} = require './keyring'
IS = constants.import_state

##=======================================================================

filter = (d, v) ->
  out = {}
  for k in v when d?
    out[k] = d[k]
  return out

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

  set_is_self : (b) -> @_is_self = b
  is_self : () -> @_is_self

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
      log.debug "- #{un}: stored user to local DB"
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
    log.debug "- loaded full sig chain"
    cb err

  #--------------

  update_sig_chain : (remote, cb) ->
    seqno = remote?.sigs?.last?.seqno
    log.debug "+ update sig chain; seqno=#{seqno}"
    await @sig_chain.update seqno, defer err, did_update
    if did_update
      @sigs.last = @sig_chain.last().export_to_user()
      log.debug "| update sig_chain last link to #{JSON.stringify @sigs}"
      @_dirty = true
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

  fingerprint : (upper_case = false) ->
    unless @_fingerprint?
      @_fingerprint =
        lc : @public_keys?.primary?.key_fingerprint?.toLowerCase()
      @_fingerprint.uc = @_fingerprint.lc?.toUpperCase()
    return @_fingerprint[if upper_case then 'uc' else 'lc']

  #--------------

  @load_me : (cb) ->
    esc = make_esc cb, "User::load_me"
    log.debug "+ User::load_me"
    await User.load { username : env().get_username() }, esc defer me
    await me._load_me_2 esc defer()
    log.debug "- User::load_me"
    cb null, me

  #--------------

  _load_me_2 : (cb) ->
    esc = make_esc cb, "User::_load_me_2"
    @set_is_self true
    @key = master_ring().make_key_from_user @, true 
    un = @username()
    log.debug "+ #{un}: checking public key"
    await @key.find esc defer()
    log.debug "- #{un}: checked public key"
    log.debug "+ #{un}: verifying user and signatures"
    await @verify esc defer()
    log.debug "- #{un}: verified users and signatures"
    cb null

  #--------------

  check_public_key : (cb) ->
    await @query_key { secret : false }, defer err
    cb err

  #--------------

  load_public_key : ({signer, can_fail}, cb) ->
    log.debug "+ load public key for #{@username()}"
    err = null
    query = { username : @username(), fingerprint : @fingerprint(), signer }
    unless @key?
      await load_key query, defer err, @key
      if err? and (err instanceof GE.GpgError) and can_fail
        log.debug "| Failed to load a key for #{@username()}, but we're allowed to failed: #{err.message}"
        err = null
    log.debug "- load public key; found=#{!!@key}; err=#{err}"
    cb err, @key

  #--------------

  username : () -> @basics.username

  #--------------

  import_public_key : ({keyring}, cb) ->
    log.debug "+ Import public key from #{keyring.to_string()}"
    @key = keyring.make_key_from_user @, false
    await @key.save defer err
    log.debug "- Import public key from #{keyring.to_string()}"
    cb err, @key

  #--------------

  check_remote_proofs : (skip, cb) ->
    await @sig_chain.check_remote_proofs { skip, pubkey : @key }, defer err, warnings
    cb err, warnings

  #--------------

  # Also serves to compress the public signatures into a usable table.
  verify : (cb) ->
    await @sig_chain.verify_sig { @key }, defer err
    cb err

  #--------------

  gen_remote_proof_gen : ({klass, remote_username}, cb) ->
    esc = make_esc cb, "User::gen_remote_proof_gen"
    await @load_public_key {}, esc defer()
    arg =  { km : @key, remote_username }
    g = new klass arg
    cb null, g

  #--------------

  gen_track_proof_gen : ({uid, track_obj, untrack_obj}, cb) ->
    esc = make_esc cb, "User::gen_track_proof_gen"
    await @load_public_key {}, esc defer()
    last_link = @sig_chain?.last()
    klass = if untrack_obj? then UntrackerProofGen else TrackerProofGen
    arg = 
      km : @key
      seqno : (if last_link? then (last_link.seqno() + 1) else 1)
      prev : (if last_link? then last_link.id else null)
      uid : uid
    arg.track = track_obj if track_obj?
    arg.untrack = untrack_obj if untrack_obj?
    g = new klass arg
    cb null, g

  #--------------

  gen_track_obj : () ->

    pkp = @public_keys.primary
    out =
      basics : filter @basics, [ "id_version", "last_id_change", "username" ]
      id : @id
      key : filter pkp, [ "kid", "key_fingerprint" ]
      seq_tail : @sig_chain?.last().to_track_obj()
      remote_proofs : @sig_chain?.remote_proofs_to_track_obj()
      ctime : unix_time()
    out

  #--------------

  remove_key : (cb) -> 
    (master_ring().make_key_from_user @, false).remove cb

  #--------------

  # Make a new temporary keyring; initialize it with the user's current
  # public key and/or private key, depending on the passed options.  If we fail
  # halfway through, make sure we nuke and clean up after ourselves.
  new_tmp_keyring : ({secret}, cb) ->
    tmp = err = null
    log.debug "+ new_tmp_keyring for #{@username()} (secret=#{secret})"
    await TmpKeyRing.make defer err, tmp
    unless err?
      k = master_ring().make_key_from_user @, secret
      await k.load defer err2
      unless err2?
        k2 = k.copy_to_keyring tmp
        await k2.save defer err2
      if err2?
        err = err2
        await tmp.nuke defer err3
        tmp = null
    log.debug "- new_tmp_keyring -> #{err}"
    cb err, tmp

  #--------------

  gen_untrack_obj : () ->

    pkp = @public_keys.primary
    out =
      basics : filter @basics, [ "id_version", "last_id_change", "username" ]
      id : @id
      key : filter pkp, [ "kid", "key_fingerprint" ]
    out

##=======================================================================

