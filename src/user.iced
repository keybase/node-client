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
libkeybase = require 'libkeybase'
tor = require './tor'
colors = require './colors'
kbpgp = require 'kbpgp'
{merkle_client} = require './merkle_client'

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

  @FIELDS : [ "basics", "public_keys", "id", "merkle_data", "private_keys", "logged_in" ]

  #--------------

  constructor : (args) ->
    for k in User.FIELDS
      @[k] = args[k]
    @_dirty = false
    @sig_chain = null
    @_is_self = false
    @_have_secret_key = false
    @sibkeys = []
    @gpg_keys = []

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
    if (ph = @merkle_data?.payload_hash)?
      log.debug "| loading sig chain w/ payload hash #{ph}"
      await SigChain.load @id, @username(), ph, defer err, @sig_chain
    else
      log.debug "| No payload hash tail pointer found"
      @sig_chain = new SigChain @id, @username()
    log.debug "- loaded sig chain from local storage"
    cb err

  #--------------

  load_full_sig_chain : (cb) ->
    log.debug "+ load full sig chain"
    sc = new SigChain @id, @username()
    await sc.update null, defer err
    @sig_chain = sc unless err?
    log.debug "- loaded full sig chain"
    cb err

  #--------------

  update_sig_chain : (remote_seqno, cb) ->
    log.debug "+ update sig chain; remote_seqno=#{remote_seqno}"
    await @sig_chain.update remote_seqno, defer err, did_update
    if did_update
      last = @sig_chain.last().export_to_user()
      log.debug "| update sig_chain last link to #{JSON.stringify last}"
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
    else
      # Always update fields, irrespective of whether the id_version has
      # actually increased, because the server format might've changed.
      @update_fields remote

    if not err?
      await @update_sig_chain remote.merkle_data?.seqno, defer err

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

    if self and secret and not tor.strict()
      log.debug "| Checking session since we're loading User as self (and need secret key)"
      await session.load_and_check esc defer()

    if (self and tor.strict())
      log.warn "Tor strict mode: #{colors.bold('not')} syncing your profile with the server"
    else
      fetched_from_server = true
      await User.load_from_server {self, secret, username, local_user: local}, esc defer remote

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
    else if tor.strict()
      err = new E.TorStrictError "Can't load your info from the server in strict Tor mode"
    else
      err = new E.NotFoundError "User #{username} wasn't found"

    await athrow err, esc defer() if err?

    if require_public_key and not user.merkle_data?.eldest_kid?
      await athrow new Error("user doesn't have a public key"), esc defer()

    if not user.public_keys?.all_bundles?
      await athrow new Error("User key bundles missing."), esc defer()
    await libkeybase.ParsedKeys.parse { key_bundles: user.public_keys.all_bundles }, esc defer parsed_keys

    # Verify the user's sigchain, even if it's empty. This at least checks
    # ownership of an eldest PGP key.
    # TODO: Enable verification caching.
    log.debug "+ #{username}: verifying signatures"
    await user._verify {parsed_keys, self}, esc defer()
    log.debug "- #{username}: verified signatures"

    # If we fetched from the server, store the new data to disk.
    if fetched_from_server
      await user.store force_store, esc defer()

    log.debug "- #{username}: loaded user"

    # Cache in some cases...
    User.cache[username] = user if cache and not err? and user?
    cb err, user

  #--------------

  @load_from_server : ({self, secret, username, local_user}, cb) ->
    esc = make_esc cb, "User::load_from_server"
    log.debug "+ #{username}: load user from server"

    # If we've loaded the user before in this process, the result is cached in
    # memory. Short circuit and return that.
    if (ret = User.server_cache[username])?
      log.debug "| hit server cache"
      cb null, ret
      return

    # Load the user's Merkle tip.
    await merkle_client().find_and_verify {username}, esc defer leaf, root, server_id_version

    # If the user's Merkle leaf exists (meaning they have an eldest key at all,
    # i.e. not a newly-created empty user), check it against past Merkle tree
    # data and maybe short circuit.
    local_id_version = local_user?.basics?.id_version
    local_seqno = local_user?.merkle_data?.seqno
    if leaf?
      pub = leaf.get_public()
      server_seqno = pub?.seqno
      if (server_id_version == local_id_version and
          server_seqno == local_seqno and
          local_user._format_up_to_date {})
        # Nothing new to load. Short-circuit.
        log.debug "| id_version (#{local_id_version}) and seqno (#{local_seqno}) haven't changed."
        cb null, null
        return
      else if server_id_version < local_id_version
        cb new Error("Server id version (#{server_id_version}) rolled back from local (#{local_id_version})")
        return
      else if server_seqno < local_seqno
        cb new Error("Server seqno (#{server_seqno}) rolled back from local (#{local_seqno})")
        return
      if pub?
        seqno = pub.seqno
        # The Merkle tree gives a short sig_id. Add the common suffix.
        sig_id = pub.sig_id + libkeybase.SIG_ID_SUFFIX
        payload_hash = pub.payload_hash
      merkle_data = {
        seqno,
        sig_id,
        payload_hash,
        eldest_kid: leaf.get_eldest_kid()
      }
    else
      # No Merkle leaf exists, because user has no key history.
      merkle_data = null

    # Load the full user from the server.
    args =
      endpoint : "user/lookup"
      args : {username }
      need_cookie : (self and secret)
    await req.get args, esc defer body
    ret = new User body.them
    ret.set_logged_in()

    # Attach merkle-tree info to the user. This will get saved when we store
    # the user on disk.
    ret.merkle_data = merkle_data

    User.server_cache[username] = ret
    log.debug "- #{username}: loaded user from server"
    cb null, ret

  #--------------

  _format_up_to_date : ({}) ->
    # Check for new server fields that might be missing in old cached data.
    if not @public_keys?.all_bundles?
      return false
    return true

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
        lc : @default_key()?.fingerprint().toString('hex')
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
    await akatch (() -> libkeybase.assertion.URI.parse { s : username, strict : false }), esc defer uri
    unless uri.is_keybase()
      await req.get { endpoint : "user/lookup", args : uri.to_lookup_query() }, esc defer body
      if body.them.length is 0
        err = new E.NotFoundError "No user found for '#{username}'"
      else if body.them.length > 1
        err = new E.AmbiguityError "Multiple results returned for '#{username}'; expected only 1"
      else
        username = body.them[0].basics.username
        ass_out = uri

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

  _load_me_2 : ({secret, maybe_secret, install_key, verify_opts }, cb) ->
    esc = make_esc cb, "User::_load_me_2"
    un = @username()
    @set_is_self true

    # If the user has no keys at all, short-circuit.
    if @sibkeys.length == 0
      cb null
      return

    load_secret = secret or maybe_secret
    if load_secret
      await master_ring().make_secret_gpg_key_from_user {user: @}, defer err, @key
    else
      # Just pick one available public key, for backwards compatibility.
      @key = @default_key()
      log.debug "+ #{un}: checking public key"
      await @key.find defer err
      log.debug "- #{un}: checked public key"

    if not err? and load_secret
      @set_have_secret_key true
    else if err? and (err instanceof E.NoLocalKeyError) and maybe_secret
      # Fall back to same as above.
      @key = @default_key()
      log.debug "+ #{un}: checking public key"
      await @key.find defer err
      log.debug "- #{un}: checked public key"

    if err? and (err instanceof E.NoLocalKeyError) and install_key
      do_install = true
    else if err?
      await athrow err, esc defer()
    else
      do_install = false

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
      if secret
        await master_ring().make_secret_gpg_key_from_user {user: @}, defer err, key
      else
        key = @default_key()
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

  import_public_keys : ({keyring}, cb) ->
    esc = make_esc cb, "User::import_public_keys"
    log.debug "+ Import public keys from #{keyring.to_string()}"
    for key in @gpg_keys
      await key.save esc defer()
    log.debug "- Import public keys from #{keyring.to_string()}"
    cb null

  #--------------

  display_cryptocurrency_addresses : (opts, cb) ->
    await @sig_chain.display_cryptocurrency_addresses opts, defer err
    cb err

  #--------------

  check_remote_proofs : (opts, cb) ->
    opts.gpg_keys = @gpg_keys
    opts.username = @username()
    await @sig_chain.check_remote_proofs opts, defer err, warnings, n_proofs
    cb err, warnings, n_proofs

  #--------------

  # Also serves to compress the public signatures into a usable table.
  _verify : ({opts, parsed_keys, self}, cb) ->
    esc = make_esc cb, "User::verify"
    @sibkeys = []
    @gpg_keys = []

    # If there is no eldest key, then this is a new account or it just did a
    # total account reset. Short-circuit.
    if not @merkle_data?.eldest_kid?
      cb null
      return

    # Verify the chain!
    # XXX: In the one case of a KeyOwnershipError for the user's *own*
    # sigchain, suppress the error. This can come up if you've uploaded a PGP
    # key that doesn't include your identity in it, but you haven't signed any
    # links yet. This is a tricky case to get right, so make sure to think
    # about it / test it when changing this code.
    await @sig_chain.verify_sig { opts, @key, parsed_keys, @merkle_data }, defer err, @sibkeys
    if err?
      if self and (err instanceof libkeybase.E.KeyOwnershipError)
        log.warn "You have not proven ownership of your key. Run `keybase push --update`."
        @sibkeys = [parsed_keys.get_merged_pgp_key_manager @merkle_data.eldest_kid]
      else
        cb err
        return

    @gpg_keys = master_ring().make_all_public_gpg_keys_from_user {user: @}
    cb null

  #--------------

  # BACKWARDS COMPATIBILITY for parts of the code that still think there's only
  # one key.
  default_key : () ->
    @gpg_keys[0]

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
      arg.eldest_kid = @merkle_data.eldest_kid
      arg.km = @key
      arg.merkle_root = @merkle_root()
      arg.client = (new PackageJson()).track_obj()
      ret = new klass arg
    cb err, ret

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
      key :
        kid : @merkle_data?.eldest_kid
      seq_tail : @sig_chain?.true_last()?.to_track_obj()
      remote_proofs : @sig_chain?.remote_proofs_to_track_obj()
      ctime : unix_time()
    out

  #--------------

  remove_key : (cb) ->
    esc = make_esc cb, "User::remove_key"
    for key in @gpg_keys
      await key.remove esc defer()
    cb null

  #--------------

  gen_untrack_obj : () ->

    pkp = @public_keys.primary
    out =
      basics : filter @basics, [ "id_version", "last_id_change", "username" ]
      id : @id
      key : filter pkp, [ "kid", "key_fingerprint" ]
    out

##=======================================================================

