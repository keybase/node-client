req = require './req'
db = require './db'
{constants} = require './constants'
{chain_err,make_esc} = require 'iced-error'
{GE,E} = require './err'
deepeq = require 'deep-equal'
{SigChain} = require './sigchain'
log = require './log'
{UntrackerProofGen,TrackerProofGen} = require './sigs'
{session} = require './session'
{env} = require './env'
{TrackWrapper} = require './trackwrapper'
{fpeq,unix_time} = require('pgp-utils').util
{QuarantinedKeyRing,TmpKeyRing,load_key,master_ring} = require './keyring'
{athrow,akatch} = require('iced-utils').util
IS = constants.import_state
{PackageJson} = require('./package')
{assertion} = require 'libkeybase'
tor = require './tor'

##=======================================================================

filter = (d, v) ->
  out = {}
  for k in v when d?
    out[k] = d[k]
  return out

##=======================================================================

exports.User = class User

  #--------------

  @cache : {}
  @server_cache : {}

  @FIELDS : [ "basics", "public_keys", "id", "sigs", "private_keys", "logged_in" ]

  #--------------

  constructor : (args) ->
    for k in User.FIELDS
      @[k] = args[k]
    @_dirty = false
    @sig_chain = null
    @_is_self = false
    @_have_secret_key = false

  #--------------

  set_logged_in : () -> @logged_in = session.logged_in()

  #--------------

  set_is_self : (b) -> @_is_self = b
  is_self : () -> @_is_self
  set_have_secret_key : (b) -> @_have_secret_key = b
  have_secret_key : -> @_have_secret_key

  #--------------

  to_obj : () ->
    out = {}
    for k in User.FIELDS
      out[k] = @[k]
    return out

  #--------------

  public_key_bundle : () -> @public_keys?.primary?.bundle
  private_key_bundle : () -> @private_keys?.primary?.bundle

  #--------------

  names : () ->
    ret = [ { type : constants.lookups.username, name : @basics.username } ]
    if (ki64 = @key_id_64())?
      ret.push { type : constants.lookups.key_id_64_to_user, name : ki64 }
    if (fp = @fingerprint false)?
      ret.push { type : constants.lookups.key_fingerprint_to_user, name : fp }
    return ret

  #--------------

  store : (force_store, cb) ->
    err = null
    un = @username()
    if force_store or @_dirty
      log.debug "+ #{un}: storing user to local DB"
      await db.put { key : @id, value : @to_obj(), names : @names() }, defer err
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
      log.debug "| No payload hash tail pointer found"
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
    @sigs or= {}
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
    else if (not a?) or (a < b) or (session.logged_in() && not(@logged_in))
      log.debug "| version update needed: #{a} vs. #{b} (logged_in=#{@logged_in})"
      @update_fields remote
    else if a isnt b
      err = new E.CorruptionError "Bad ids on user objects: #{a.id} != #{b.id}"

    if not err?
      await @update_sig_chain remote, defer err

    log.debug "- finished update"

    cb err

  #--------------

  @map_key_to_user_local : (query, cb) ->
    log.debug "+ map_key_to_user_local #{JSON.stringify query}"
    err = ret = null
    await db.lookup query, defer err, row
    k = JSON.stringify query
    if err? then # noop
    else if not row?
      err = new E.NotFoundError "Key not found for query #{k}"
    else
      b = row.basics
      ret = { uid : b.uid, username : b.username }
    log.debug "- map_key_to_user_local -> #{err}"
    cb err, ret

  #--------------

  @map_key_to_user : (query, cb) ->
    log.debug "+ map_key_to_user: #{JSON.stringify query}"
    await User.map_key_to_user_local query, defer err, basics
    await User.map_key_to_user_remote query, defer err, basics if err?
    log.debug "- mapped -> #{err}"
    cb err, basics

  #--------------

  @map_key_to_user_remote : (query, cb) ->
    qs = JSON.stringify query
    log.debug "+ #{qs}: map to username"
    err = null
    L = constants.lookups
    body = null
    key = switch query.type
      when L.key_fingerprint_to_user then 'fingerprint'
      when L.key_id_64_to_user then 'pgp_key_id'
      else
        err = new E.BadQueryError "Bad query type: #{query.type}"
        null
    unless err?
      d = {}
      d[key] = query.name
      req_args =
        endpoint : "key/basics"
        args : d
      await req.get req_args, defer err, body
    log.debug "- #{qs}: map -> #{err}"
    cb err, body

  #--------------

  @load : ({username,ki64,require_public_key, cache, self, secret}, cb) ->
    err = null
    if username? and (ret = User.cache[username])?
      log.debug "| hit user cache for #{username}"
    else
      await User._load2 { username, ki64, require_public_key, cache, self, secret}, defer err, ret
    cb err, ret

  #--------------

  @_load2 : ({username,ki64,require_public_key, cache, self, secret}, cb) ->
    esc = make_esc cb, "User::load"
    k = if username? then username else "Key: #{ki64}"
    log.debug "+ #{username}: load user"

    await User.load_from_storage {username,ki64}, esc defer local

    # If we need to, get the new username
    if not username? then username = local?.basics?.username

    if self and secret and not tor.paranoid()
      log.debug "| Checking session since we're loading User as self (and need secret key)"
      await session.load_and_check esc defer()

    if (self and tor.paranoid())
      log.debug "| Skipping remote server check for ME in tor paranoid mode"
    else
      await User.load_from_server {self, secret, username}, esc defer remote

    if require_public_key and not remote.public_keys?.primary?
      await athrow new Error("user doesn't have a public key"), esc defer()

    changed = true
    force_store = false
    if local?
      user = local
      if remote?
        await user.update_with remote, esc defer()
    else if remote?
      user = remote
      await user.load_full_sig_chain esc defer()
      force_store = true
    else
      err = new E.NotFoundError "User #{username} wasn't found"
      await athrow err, esc defer()

    if (self and tor.paranoid())
      log.debug "| Skipping merkle-tree check for ME in tor paranoid mode"
    else

      # This might noop or just warn depending on the user's preferences
      await user.check_merkle_tree esc defer()

      # Finally we can store... If we actually fetched anything, which
      # didn't happen in the case of (self and tor.paranoid())
      await user.store force_store, esc defer()

    log.debug "- #{username}: loaded user"

    # Cache in some cases...
    User.cache[username] = user if cache and not err? and user?
    cb err, user

  #--------------

  @load_from_server : ({self, secret, username}, cb) ->
    log.debug "+ #{username}: load user from server"
    if (ret = User.server_cache[username])?
      log.debug "| hit server cache"
    else
      args =
        endpoint : "user/lookup"
        args : {username }
        need_cookie : (self and secret)
      await req.get args, defer err, body
      ret = null
      unless err?
        ret = new User body.them
        ret.set_logged_in()
        User.server_cache[username] = ret
    log.debug "- #{username}: loaded user from server"
    cb err, ret

  #--------------

  @load_from_storage : ({username, ki64}, cb) ->
    name = username or ki64
    log.debug "+ #{name}: load user from local storage"
    type = if username? then constants.lookups.username else constants.lookups.key_id_64_to_user
    await db.lookup { type, name }, defer err, row
    if not err? and row?
      ret = new User row
      await ret.load_sig_chain_from_storage defer err
      if err?
        ret = null
    log.debug "- #{name}: loaded user from local storage -> #{err} / #{ret}"
    cb err, ret

  #--------------

  fingerprint : (upper_case = false) ->
    unless @_fingerprint?
      @_fingerprint =
        lc : @public_keys?.primary?.key_fingerprint?.toLowerCase()
      @_fingerprint.uc = @_fingerprint.lc?.toUpperCase()
    return @_fingerprint[if upper_case then 'uc' else 'lc']

  #--------------

  key_id_64 : () ->
    if (fp = @fingerprint false)? then fp[-16...] else null

  #--------------

  #
  # @resolve_user_name
  #
  # Given a username like reddit://maxtaco or fingerprint://aa99ee or keybase://max,
  # resolve to a regular keybase username, like max.
  #
  @resolve_user_name : ({username}, cb) ->
    log.debug "+ resolving username #{username}"
    esc = make_esc cb, "resolve_user_name"
    err = null
    await akatch (() -> assertion.URI.parse { s : username, strict : false }), esc defer uri
    unless uri.is_keybase()
      await req.get { endpoint : "user/lookup", args : uri.to_lookup_query() }, esc defer body
      if body.them.length is 0
        err = new E.NotFoundError "No user found for '#{username}'"
      else if body.them.length > 1
        err = new E.AmbiguityError "Multiple results returned for '#{username}'; expected only 1"
      else
        username = body.them[0].basics.username
        ass_out = uri

        # Prime the cache for other subsequent lookups for this user.
        user = new User body.them[0]
        user.set_logged_in()
        User.server_cache[username] = user

    log.debug "- resolved to #{username}"
    cb err, username, ass_out

  #--------------

  #
  # load_me
  #
  # Loads the me user from some combination of the server and local storage.
  # The me user can be loaded with or without a secret key, depending on the opts,
  # but a public key is required.
  #
  # @param {Object} opts the load options
  # @option {Bool} opts.secret whether to load the secret key or not.
  # @option {Bool} opts.install_key whether to install a key if it wasn't found
  # @param {Callback} cb Callback with an `<Error,User>` pair, with error set
  #   on failure, and null on success.
  #
  @load_me : (opts, cb) ->
    esc = make_esc cb, "User::load_me"
    log.debug "+ User::load_me"
    unless (username = env().get_username())?
      await athrow (new E.NoUsernameError "no username for current user; try `keybase login`"), esc defer()
    await User.load { username, self : true, secret : opts.secret }, esc defer me
    await me._load_me_2 opts, esc defer()
    log.debug "- User::load_me"
    cb null, me

  #--------------

  # Check that the end of this user's sig chain shows up in the current merkle
  # root (as it should!)
  check_merkle_tree : (cb) ->

    # Checking the Merkle tree for this user means getting the current
    # root, descending the tree for the user, and then ensuring that the
    # root points to the end of the user's chain tail.
    err = null
    mode = env().get_merkle_checks()
    explain = "Likely this is a bug or transient error; but the server could be compromised"

    if not mode.is_none()
      await @sig_chain.check_merkle_tree defer err
      if not err? then # noop
      else if mode.is_strict()
        log.error "Failed to match user's signature with sitewide state"
        log.error explain
      else
        log.warn "When checking #{@username()}: #{err}"
        log.warn explain
        err = null
    cb err

  #--------------

  _load_me_2 : ({secret, maybe_secret, install_key, verify_opts }, cb) ->
    esc = make_esc cb, "User::_load_me_2"
    @set_is_self true
    load_secret = secret or maybe_secret
    @key = master_ring().make_key_from_user @, load_secret
    un = @username()

    log.debug "+ #{un}: checking #{if load_secret then 'secret' else 'public'} key"
    await @key.find defer err
    log.debug "- #{un}: checked #{if load_secret then 'secret' else 'public'} key"

    if not err? and load_secret
      @set_have_secret_key true
    else if err? and (err instanceof E.NoLocalKeyError) and maybe_secret
      @key = master_ring().make_key_from_user @, false
      log.debug "+ #{un}: check try 2, fallback to public"
      await @key.find defer err
      log.debug "- #{un}: check try 2, fallback to public"

    if err? and (err instanceof E.NoLocalKeyError) and install_key
      do_install = true
    else if err?
      await athrow err, esc defer()
    else
      do_install = false

    log.debug "+ #{un}: verifying user and signatures"
    await @verify (verify_opts or {}), esc defer()
    log.debug "- #{un}: verified users and signatures"

    if do_install
      await @key.commit {}, esc defer()

    cb null

  #--------------

  # Checks to see if the user has the key locally or remotely.
  check_key : ({secret, store}, cb) ->
    ret = {}
    log.debug "+ #{@username()}: check public key"
    if @fingerprint()?
      ret.remote = (not(secret) or @private_key_bundle()?)
      key = master_ring().make_key_from_user @, secret
      await key.find defer err
      if not err?
        ret.local = true
        @key = key if store
      else if (err instanceof E.NoLocalKeyError)
        err = null
        ret.local = false
    log.debug "- #{@username()}: check_public_key: ret=#{JSON.stringify ret}; err=#{err}"
    cb err, ret

  #--------------

  load_public_key : ({signer}, cb) ->
    log.debug "+ load public key for #{@username()}"
    err = null
    unless @key?
      query = { username : @username(), fingerprint : @fingerprint() }
      await load_key query, defer err, @key
    log.debug "- load public key; found=#{!!@key}; err=#{err}"
    cb err, @key

  #--------------

  username : () -> @basics.username

  #--------------

  reference_public_key : ({keyring}, cb) ->
    @key = keyring.make_key_from_user @, false

  #--------------

  import_public_key : ({keyring}, cb) ->
    log.debug "+ Import public key from #{keyring.to_string()}"
    @key = keyring.make_key_from_user @, false
    await @key.save defer err
    log.debug "- Import public key from #{keyring.to_string()}"
    cb err, @key

  #--------------

  display_cryptocurrency_addresses : (opts, cb) ->
    await @sig_chain.display_cryptocurrency_addresses opts, defer err
    cb err

  #--------------

  check_remote_proofs : (opts, cb) ->
    opts.pubkey = @key
    opts.username = @username()
    await @sig_chain.check_remote_proofs opts, defer err, warnings, n_proofs
    cb err, warnings, n_proofs

  #--------------

  # Also serves to compress the public signatures into a usable table.
  verify : (opts, cb) ->
    await @sig_chain.verify_sig { opts, @key }, defer err
    cb err

  #--------------

  list_remote_proofs : (opts) -> @sig_chain?.list_remote_proofs(opts)
  list_trackees : () -> @sig_chain?.list_trackees()
  list_cryptocurrency_addresses : () -> @sig_chain?.list_cryptocurrency_addresses()
  merkle_root : () -> @sig_chain?.merkle_root_to_track_obj()

  #--------------

  gen_remote_proof_gen : ({klass, remote_name_normalized, sig_id, supersede }, cb) ->
    arg = {
      remote_name_normalized,
      sig_id,
      supersede
    }
    await @gen_sig_base { klass, arg }, defer err, ret
    cb err, ret

  #--------------

  gen_sig_base : ({klass, arg}, cb) ->
    ret = null
    await @load_public_key {}, defer err
    unless err?
      arg.km = @key
      arg.merkle_root = @merkle_root()
      arg.client = (new PackageJson()).track_obj()
      ret = new klass arg
    cb null, ret

  #--------------

  gen_track_proof_gen : ({uid, track_obj, untrack_obj}, cb) ->
    last_link = @sig_chain?.true_last()
    klass = if untrack_obj? then UntrackerProofGen else TrackerProofGen
    arg =
      seqno : (if last_link? then (last_link.seqno() + 1) else 1)
      prev : (if last_link? then last_link.id else null)
      uid : uid
    arg.track = track_obj if track_obj?
    arg.untrack = untrack_obj if untrack_obj?
    await @gen_sig_base { klass, arg }, defer err, ret
    cb err, ret

  #--------------

  gen_track_obj : () ->

    pkp = @public_keys.primary
    out =
      basics : filter @basics, [ "id_version", "last_id_change", "username" ]
      id : @id
      key : filter pkp, [ "kid", "key_fingerprint" ]
      seq_tail : @sig_chain?.true_last()?.to_track_obj()
      remote_proofs : @sig_chain?.remote_proofs_to_track_obj()
      ctime : unix_time()
    out

  #--------------

  remove_key : (cb) ->
    (master_ring().make_key_from_user @, false).remove cb

  #--------------

  # Import this user's key into a quarantined keyring, so we can
  # run some tests on it before we accept it into our main keyring.
  make_quarantined_keyring : (cb) ->
    ret = err = null

    cleanup = (cb) ->
      if err? and ret?
        await ret.nuke defer e2
        log.warn "Error in deleting quarantined keyring: #{e2.message}" if e2?
      cb()

    cb = chain_err cb, cleanup
    esc = make_esc cb, "make_quarantined_keyring"
    log.debug "+ make_quarantined_keyring for #{@username()}"
    await QuarantinedKeyRing.make esc defer tmp
    ret = tmp
    key = ret.make_key_from_user @, false
    await key.save esc defer()
    await ret.list_fingerprints esc defer fps

    err = if fps.length is 0 then new E.ImportError "Import failed: no fingerprint came out!"
    else if fps.length > 1 then new E.CorruptionError "Import failed: found >1 fingerprints!"
    else if (a = @fingerprint())? and not fpeq(a, (b = fps[0]))
      new E.BadFingerprintError "Bad fingerprint: #{a} != #{b}; server lying?"
    else
      ret.set_fingerprint fps[0]
      @key = key
      null

    log.debug "- make_quarantined_keyring -> #{err}"
    cb err, ret

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

