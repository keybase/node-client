
{GPG} = require './gpg'
{chain,make_esc} = require 'iced-error'
{mkdir_p} = require('iced-utils').fs
{prng} = require 'crypto'
pgp_utils = require('pgp-utils')
{trim,fingerprint_to_key_id_64,fpeq,athrow,base64u} = pgp_utils.util
{userid} = pgp_utils
{E} = require './err'
path = require 'path'
fs = require 'fs'
{colgrep} = require './colgrep'
util = require 'util'
os = require 'os'
{a_json_parse} = require('iced-utils').util
{list_fingerprints,Parser} = require('./index')

##=======================================================================

strip = (m) -> m.split(/\s+/).join('')

states =
  NONE : 0
  LOADED : 1
  SAVED : 2

##=======================================================================

exports.Log = class Log
  constructor : ->
  debug : (x) -> console.error x
  warn : (x) -> console.error x
  error : (x) -> console.error x
  info : (x) -> console.error x

##=======================================================================

exports.Globals = class Globals

  constructor : ({@get_preserve_tmp_keyring,
                  @get_debug,
                  @get_tmp_keyring_dir,
                  @get_key_klass,
                  @get_home_dir,
                  @get_gpg_cmd,
                  @get_no_options,
                  @log}) ->
    @get_preserve_tmp_keyring or= () -> false
    @log or= new Log
    @get_debug or= () -> false
    @get_tmp_keyring_dir or= () -> os.tmpdir()
    @get_key_klass or= () -> GpgKey
    @get_home_dir or= () -> null
    @get_gpg_cmd or= () -> null
    @get_no_options or= () -> false
    @_mring = null

  master_ring : () -> @_mring
  set_master_ring : (r) -> @_mring = r

#----------------

_globals = new Globals {}
globals = () -> _globals

#----------------

exports.init = (d) ->
  _globals = new Globals d
  _globals.set_master_ring new MasterKeyRing()

#----------------

log = () -> globals().log

##=======================================================================

exports.GpgKey = class GpgKey

  #-------------

  constructor : (fields) ->
    @_state = states.NONE
    for k,v of fields
      @["_#{k}"] = v

  #-------------

  # The fingerprint of the key
  fingerprint : () -> @_fingerprint

  # The 64-bit GPG key ID
  key_id_64 : () -> @_key_id_64 or (if @fingerprint() then @fingerprint()[-16...] else null)

  # Something to load a key by
  load_id : () -> @key_id_64() or @fingerprint() or @username()

  # The keybase username of the keyholder
  username : () -> @_username

  # The keybase UID of the keyholder
  uid : () -> @_uid

  # All uids, available after a load from the keyring
  all_uids : () -> @_all_uids

  # Return the raw armored PGP key data
  key_data : () -> @_key_data

  # The keyring object that we've wrapped in
  keyring : () -> @_keyring

  # These three functions are to fulfill to key manager interface
  get_pgp_key_id : () -> @key_id_64()
  get_pgp_fingerprint : () -> @fingerprint().toLowerCase()
  get_ekid : () -> null

  is_signed : () -> !!@_is_signed

  #-------------

  check_is_signed : (signer, cb) ->
    log().debug "+ Check if #{signer.to_string()} signed #{@to_string()}"
    id = @load_id()
    args = [ "--list-sigs", "--with-colons", id ]
    await @gpg { args }, defer err, out
    unless err?
      rows = colgrep { buffer : out, patterns : { 0 : /^sig$/ }, separator : /:/  }
      to_find = signer.key_id_64().toUpperCase()
      for row in rows
        if row[4] is to_find
          log().debug "| Found in row: #{JSON.stringify row}"
          @_is_signed = true
          break
    log().debug "- Check -> #{@_is_signed}"
    cb err, @_is_signed

  #-------------

  # Find the key in the keyring based on fingerprint
  find : (cb) ->
    if (fp = @fingerprint())?
      args = [ "-" + (if @_secret then 'K' else 'k'), "--with-colons", fp ]
      await @gpg { args, quiet : true }, defer err, out
      if err?
        err = new E.NotFoundError "Key for #{@to_string()} not found"
    else
      err = new E.NoFingerprintError "No fingerprint given for #{@_username}"
    cb err

  #-------------

  # Check that this key has been signed by the signing key.
  check_sig : (signing_key, cb) ->
    args = [ '--list-sigs', '--with-colon', @fingerprint() ]
    await @gpg { args }, defer err, out
    unless err?
      rows = colgrep { buffer : out, patterns : {
          0 : /^sub$/
          4 : (new RegExp "^#{signing_key.key_id_64()}$", "i")
        }
      }
      if rows.length is 0
        err = new E.VerifyError "No signature of #{@to_string()} by #{signing_key.to_string()}"
    cb err

  #-------------

  set_keyring : (r) -> @_keyring = r

  #-------------

  to_string : () -> [ @username(), @key_id_64() ].join "/"

  #-------------

  gpg : (gargs, cb) -> @keyring().gpg gargs, cb

  #-------------

  # Save this key to the underlying GPG keyring
  save : (cb) ->
    args = [ "--import" ]
    args.push "--import-options", "import-local-sigs" if @_secret
    log().debug "| Save key #{@to_string()} to #{@keyring().to_string()}"
    await @gpg { args, stdin : @_key_data, quiet : true, secret : @_secret, no_options : true }, defer err
    @_state = states.SAVED
    cb err

  #-------------

  # Load this key from the underlying GPG keyring
  load : (cb) ->
    id = @load_id()
    esc = make_esc cb, "GpgKey::load"
    args = [
      (if @_secret then "--export-secret-key" else "--export" ),
      "--export-options", "export-local-sigs",
      "-a",
      id
    ]
    log().debug "| Load key #{@to_string()} from #{@keyring().to_string()} (secret=#{@_secret})"
    await @gpg { args }, esc defer @_key_data

    if not @fingerprint()?
      log().debug "+ lookup fingerprint"
      args = [ "-k", "--fingerprint", "--with-colons", id ]
      await @gpg { args, no_options : true }, esc defer out
      fp = list_fingerprints out.toString('utf8')
      if (l = fp.length) is 0
        err = new E.GpgError "Couldn't find GPG fingerprint for #{id}"
      else if l > 1
        err = new E.GpgError "Found more than one (#l) keys for #{id}"
      else
        @_state = states.LOADED
        @_fingerprint = fp[0]
        log().debug "- Map #{id} -> #{@_fingerprint} via gpg"

    if not @uid()?
      log().debug "+ lookup UID"
      await @read_uids_from_key esc defer uids
      l = uids.length
      if l is 0
        log().debug "| weird; no UIDs found"
      else
        log().debug "| got back more than one UID; using the first: (#{JSON.stringify uids})" if l > 1
        @_uid = uids[0]
        log().debug " - Map #{id} -> #{@_uid} via gpg"
      @_all_uids = uids
      log().debug "- looked up UID"
    cb err

  #-------------

  # Remove this key from the keyring
  remove : (cb) ->
    args = [
      (if @_secret then "--delete-secret-and-public-key" else "--delete-keys"),
      "--batch",
      "--yes",
      @fingerprint()
    ]
    log().debug "| Delete key #{@to_string()} from #{@keyring().to_string()}"
    await @gpg { args }, defer err
    cb err

  #-------------

  # Read the userIds that have been signed with this key
  read_uids_from_key : (cb) ->
    fp = @fingerprint()
    log().debug "+ read_uids_from_keys #{fp}"
    uids = null
    if (uids = @_my_userids)?
      log().debug "| hit cache"
    else
      args = { fingerprint : fp }
      await @keyring().read_uids_from_key args, defer err, tmp
      uids = @_my_userids = tmp
    log().debug "| got: #{if uids? then JSON.stringify(uids) else null}"
    log().debug "- read_uids_from_key -> #{err}"
    cb err, uids

  #-------------

  sign_key : ({signer}, cb) ->
    log().debug "| GPG-signing #{@username()}'s key with your key"
    args = ["--sign-key", "--batch", "--yes" ]
    skip = false
    err = null
    if signer?
      args.push "-u", signer.fingerprint()
    else
      await @keyring().has_signing_key defer err, hsk
      if err? then skip = true
      else if not hsk
        log().info "Not trying to sign key #{@to_string()} since there's no signing key available"
        skip = true
    unless skip
      args.push @fingerprint()
      await @gpg { args, quiet : true }, defer err
    cb err

  #-------------

  # Assuming this is a temporary key, commit it to the master key chain, after signing it
  commit : ({signer, sign_key, ring }, cb) ->
    esc = make_esc cb, "GpgKey::commit"
    try_sign = sign_key or signer?
    if @keyring().is_temporary()
      log().debug "+ #{@to_string()}: Commit temporary key"
      await @sign_key { signer }, esc defer() if try_sign
      await @load esc defer()
      await @remove esc defer()
      ring or= master_ring()
      await (@copy_to_keyring ring).save esc defer()
      log().debug "- #{@to_string()}: Commit temporary key"
    else if not @_is_signed
      if try_sign
        log().debug "| #{@to_string()}: signing key, since it wasn't signed"
        await @sign_key {signer}, esc defer()
      else
        log().debug "| #{@to_string()}: key wasn't signed, but signing was skipping"
    else
      log().debug "| #{@to_string()}: key was previously commited; noop"
    cb null

  #-------------

  rollback : (cb) ->
    s = @to_string()
    err = null
    if globals().get_preserve_tmp_keyring() and @keyring().is_temporary()
      log().debug "| #{s}: preserving temporary keyring by command-line flag"
    else if @keyring().is_temporary()
      log().debug "| #{s}: Rolling back temporary key"
      await @remove defer err
    else
      log().debug "| #{s}: no need to rollback key, it's permanent"
    cb err

  #-------------

  to_data_dict : () ->
    d = {}
    d[k[1...]] = v for k,v of @ when k[0] is '_'
    return d

  #-------------

  copy_to_keyring : (keyring) ->
    return keyring.make_key @to_data_dict()

  #--------------

  _find_key_in_stderr : (which, buf) ->
    err = ki64 = fingerprint = null
    d = buf.toString('utf8')
    if (m = d.match(/Primary key fingerprint: (.*)/))? then fingerprint = m[1]
    else if (m = d.match(/using [RD]SA key ([A-F0-9]{16})/))? then ki64 = m[1]
    else err = new E.VerifyError "#{which}: can't parse PGP output in verify signature"
    return { err, ki64, fingerprint }

  #--------------

  _verify_key_id_64 : ( {ki64, which, sig}, cb) ->
    log().debug "+ GpgKey::_verify_key_id_64: #{which}: #{ki64} vs #{@fingerprint()}"
    err = null
    if ki64 isnt @key_id_64()
      await @gpg { args : [ "--fingerprint", "--keyid-format", "long", ki64 ] }, defer err, out
      if err? then # noop
      else if not (m = out.toString('utf8').match(/Key fingerprint = ([A-F0-9 ]+)/) )?
        err = new E.VerifyError "Querying for a fingerprint failed"
      else if not (a = strip(m[1])) is (b = @fingerprint())
        err = new E.VerifyError "Fingerprint mismatch: #{a} != #{b}"
      else
        log().debug "| Successful map of #{ki64} -> #{@fingerprint()}"

    unless err?
      await @keyring().assert_no_collision ki64, defer err

    log().debug "- GpgKey::_verify_key_id_64: #{which}: #{ki64} vs #{@fingerprint()} -> #{err}"
    cb err

  #-------------

  verify_sig : ({which, sig, payload}, cb) ->
    log().debug "+ GpgKey::verify_sig #{which}"
    err = null
    args =
      query : @fingerprint()
      single : true
      sig : sig
      no_json : true
      keyblock : @_key_data
      secret : @_secret
    await @keyring().oneshot_verify args, defer err, out, fp

    if not err? and not(@_fingerprint?) and fp?
      @_fingerprint = fp
      log().debug "| Setting fingerprint to #{fp} as a result of oneshot_verify"

    # Check that the signature verified, and that the intended data came out the other end
    msg = if err? then "signature verification failed"
    else if @_fingerprint? and (@_fingerprint.toLowerCase() isnt fp.toLowerCase())
      "Wrong key fingerprint; was the server lying? #{@_fingerprint} != #{fp}"
    else if ((a = trim(out.toString('utf8'))) isnt (b = trim(payload))) then "wrong payload: #{a} != #{b} (#{a.length} v #{b.length})"
    else null

    # If there's an exception, we can now throw out of this function
    if msg? then err = new E.VerifyError "#{which}: #{msg}"

    log().debug "- GpgKey::verify_sig #{which} -> #{err}"
    cb err

##=======================================================================

exports.BaseKeyRing = class BaseKeyRing extends GPG

  constructor : () ->
    super { cmd : globals().get_gpg_cmd() }
    @_has_signing_key = null

  #------

  has_signing_key : (cb) ->
    err = null
    unless @_has_signing_key?
      await @find_secret_keys {}, defer err, ids
      if err?
        log().warn "Issue listing secret keys: #{err.message}"
      else
        @_has_signing_key = (ids.length > 0)
    cb err, @_has_signing_key

  #------

  make_key : (opts) ->
    klass = globals().get_key_klass()
    ret = new klass opts
    ret.set_keyring @
    return ret

  #------

  is_temporary : () -> false
  tmp_dir : () -> os.tmpdir()

  #----------------------------

  make_oneshot_ring_2 : ({keyblock, single, secret}, cb) ->
    esc = make_esc cb, "BaseKeyRing::_make_oneshot_ring_2"
    await @gpg { no_options : true, args : [ "--import"], stdin : keyblock, quiet : true, secret }, esc defer()
    await @list_fingerprints esc defer fps
    n = fps.length
    err = if n is 0 then new E.NotFoundError "key import failed"
    else if single and n > 1 then new E.PgpIdCollisionError "too many keys found: #{n}"
    else
      @_fingerprint = fps[0]
      # Eventually use PGP-utils for this, but for now....
      @_key_id_64 = @_fingerprint[-16...]
      null
    cb err, @_fingerprint

  #----------------------------

  make_oneshot_ring : ({query, single, keyblock, secret}, cb) ->
    esc = make_esc cb, "BaseKeyRing::make_oneshot_ring"
    unless keyblock?
      args = [ "-a", "--export" , query ]
      await @gpg { args, no_options : true }, esc defer keyblock
    await TmpOneShotKeyRing.make esc defer ring
    await ring.make_oneshot_ring_2 { keyblock, single, secret }, defer err, fp
    if err?
      await ring.nuke defer e2
      log().warn "Error cleaning up keyring after failure: #{e2.message}" if e2?
    cb err, ring, fp

  #----------------------------

  find_keys_full : ( {query, secret, sigs}, cb) ->
    args = [ "--with-colons", "--fingerprint" ]
    args.push if secret then "-K" else "-k"
    args.push query if query
    await @gpg { args, list_keys : true, no_options : true }, defer err, out
    res = null
    unless err?
      index = (new Parser out.toString('utf8')).parse()
      res = (@make_key(k.to_dict({secret})) for k in index.keys())
    cb err, res

  #----------------------------

  find_keys : ({query}, cb) ->
    args = [ "-k", "--with-colons" ]
    args.push query if query
    await @gpg { args, list_keys : true, no_options : true }, defer err, out
    id64s = null
    unless err?
      rows = colgrep { buffer : out, patterns : { 0 : /^pub$/ }, separator : /:/ }
      id64s = (row[4] for row in rows)
    cb err, id64s

  #----------------------------

  find_secret_keys : ({query}, cb) ->
    args = [ "-K", "--with-colons" ]
    args.push query if query

    # Don't give 'list_keys : false' since we want to check both keyrings.
    await @gpg { args }, defer err, out

    id64s = null
    unless err?
      rows = colgrep { buffer : out, patterns : { 0 : /^sec$/ }, separator : /:/ }
      id64s = (row[4] for row in rows)
    cb err, id64s

  #----------------------------

  list_fingerprints : (cb) ->
    await @gpg { args : [ "--with-colons", "--fingerprint" ] }, defer err, out
    ret = []
    unless err?
      ret = list_fingerprints out.toString('utf8')
    cb err, ret

  #----------------------------

  list_keys : (cb) ->
    await @find_keys {}, defer err, @_all_id_64s
    cb err, @_all_id_64s

  #------

  safe_inspect : (gargs) ->
    d = {}
    for k,v of gargs
      if (k is 'stdin') and gargs.secret
        v = "<redacted>"
      d[k] = v
    util.inspect d

  #------

  gpg : (gargs, cb) ->
    log().debug "| Call to #{@CMD}: #{@safe_inspect gargs}"
    gargs.quiet = false if gargs.quiet and globals().get_debug()

    #
    # THE NUCLEAR OPTION
    #
    # The nuclear option for dealing with gpg.conf files that we
    # can't deal with. I would hate to do this, but there are some options,
    # like `--primary-keyring`, that we just can't work around if they're specified
    # in `gpg.conf`.
    #
    # There's an alternative to the nuclear option, which is to make a
    # gpg.conf that's stripped of the bad options, and to reference that
    # instead. That will be a fussy operation, since we don't know where
    # the configuration is actually stored. We can guess, but we're likely to
    # be wrong, **especially** on Windows. Plus, we'll have to keep it in sync
    # (maybe rewriting our temporary copy every time we start up).
    #
    # Discovered: `gpg --gpgconf-list`, which outputs the config file in the
    # top line.  This is a start, but need to check how widely supported it is.
    #
    # For now, experts have to declare their willingness to go nuclear.
    #
    gargs.no_options = true if globals().get_no_options()

    await @run gargs, defer err, res
    cb err, res

  #------

  index2 : (opts, cb) ->
    k = if opts?.secret then '-K' else '-k'
    args = [ k, "--with-fingerprint", "--with-colons" ]
    args.push q if (q = opts.query)?
    await @gpg { args, quiet : true, no_options : true }, defer err, out
    i = w = null
    unless err?
      p = new Parser out.toString('utf8')
      i = p.parse()
      w = p.warnings()
    cb err, i, w

  #------

  read_uids_from_key :( {fingerprint, query}, cb) ->
    query = fingerprint or query
    opts = { query }
    await @index2 opts, defer err, index
    ret = if err? then null else index?.keys()?[0]?.userids()
    cb err, ret

  #------

  index : (cb) -> @index2 {}, cb

  #------

  oneshot_verify_2 : ({ring, sig, file, no_json}, cb) ->
    err = ret = null
    if file?
      await ring.verify_sig_on_file { sig, file }, defer err
    else
      await ring.verify_and_decrypt_sig { sig }, defer err, raw
      if err? then # noop
      else if no_json then ret = raw
      else
        await a_json_parse raw, defer err, ret
    cb err, ret

  #------

  oneshot_verify : ({query, single, sig, file, no_json, keyblock, secret}, cb) ->
    log().debug "+ oneshot verify"
    ring = null
    clean = (cb) ->
      log().debug "| oneshot clean"
      if ring?
        await ring.nuke defer err
        log().warn "Error cleaning up 1-shot ring: #{err.message}" if err?
      cb()
    cb = chain cb, clean
    esc = make_esc cb, "BaseKeyRing::oneshot_verify"
    ret = null
    await @make_oneshot_ring { query, single, keyblock, secret }, esc defer ring, fp
    await @oneshot_verify_2 { ring, sig, file, no_json }, esc defer ret
    log().debug "- oneshot verify -> ok! (fp=#{fp})"
    cb null, ret, fp

##=======================================================================

exports.MasterKeyRing = class MasterKeyRing extends BaseKeyRing

  to_string : () -> "master keyring"

  mutate_args : (gargs) ->
    if (h = globals().get_home_dir())?
      gargs.args = [ "--homedir", h ].concat gargs.args
      log().debug "| Mutate GPG args; new args: #{gargs.args.join(' ')}"

##=======================================================================

exports.make_ring = (d) ->
  klass = if d? then AltKeyRing else MasterKeyRing
  new klass d

##=======================================================================

exports.reset_master_ring = reset_master_ring = () ->
  globals().set_master_ring new MasterKeyRing()

#----------

exports.master_ring = master_ring = () -> globals().master_ring()

##=======================================================================

exports.load_key = (opts, cb) ->
  delete opts.signer if (signer = opts.signer)?
  key = master_ring().make_key opts
  await key.load defer err
  if not err? and signer?
    await key.check_is_signed signer, defer err
  cb err, key

##=======================================================================

class RingFileBundle

  FILES :
    secring :
      arg : "secret-keyring"
      default : ""
    pubring :
      arg : "keyring"
      default : ""
    trustdb :
      arg : "trustdb-name"
      default : "016770670303010501020000532b0f0c000000000000000000000000000000000000000000000000"

  #-----

  constructor : ({@dir, pub_only, @no_default, @primary}) ->
    @_files = {}
    which = if pub_only then [ "pubring" ] else [ "pubring", "secring", "trustdb" ]
    for w in which
      @_files[w] = @get_file w

  #-------

  get_file : (which) -> path.join(@dir, [which, "gpg"].join("."))

  #---------

  mutate_args : (gargs, opts = {}) ->
    prepend = []
    prepend.push("--no-default-keyring") if @no_default or opts.no_default
    for w, file of @_files
      arg = if (w is 'pubring' and @primary) then "primary-keyring" else @FILES[w].arg
      prepend.push "--#{arg}", file
    gargs.args = prepend.concat gargs.args

  #---------

  touch : (which, f, cb) ->
    log().debug "+ Make/check empty #{which} #{f}"
    ok = true
    await fs.open f, "ax", 0o600, defer err, fd
    if not err?
      log().debug "| Made a new one"
      d = new Buffer @FILES[which].default, "hex"
      await fs.write fd, d, 0, d.length, null, defer e2
      log().error "Write failed: #{e2.message}" if e2?
    else if err.code is "EEXIST"
      log().debug "| Found one"
    else
      log().warn "Unexpected error code from file touch #{f}: #{err.message}"
      ok = false
    if fd >= 0 and not err?
      await fs.close fd, defer e2
      log().error "Close failed: #{e2.message}" if e2?
    log().debug "- Made/check empty #{which} -> #{ok}"
    cb null

  #---------

  touch_all : (cb) ->
    esc = make_esc cb, "RingFileBundle::touch_all"
    for which, f of @_files
      await @touch which, f, esc defer()
    cb null

##=======================================================================

class AltKeyRingBase extends BaseKeyRing

  constructor : (@dir) ->
    super()
    @_rfb = @make_ring_file_bundle()

  #------

  to_string : () -> "keyring #{@dir}"

  #------

  make_ring_file_bundle : () ->
    new RingFileBundle { @dir, no_default : true }

  #------

  mkfile : (n) -> path.join @dir, n

  #------

  post_make : (cb) -> @_rfb.touch_all cb

  #------

  @make : (klass, dir, cb, opts) ->
    opts or= {}
    tmp = not opts.perm
    type = if tmp then "temporary" else "permanent"
    parent = path.dirname dir
    nxt = path.basename dir

    mode = 0o700
    log().debug "+ Make new #{type} keychain"
    log().debug "| mkdir_p parent #{parent}"

    # If we're making a temporary directory, we can silently
    # make all parent directories, but we have to make the directory
    # itself.  If we're making a permanent directory, we can
    # make the target directory with mkdir_p and call it quits.
    targ = if tmp then parent else dir
    await mkdir_p targ, mode, defer err, made
    if err?
      log().error "Error making keyring dir #{parent}: #{err.message}"
    else if made
      log().info "Creating #{type} keyring dir: #{targ}"
    else
      await fs.stat targ, defer err, so
      if err?
        log().error "Failed to stat directory #{targ}: #{err.message}"
      else if (so.mode & 0o777) isnt mode
        await fs.chmod targ, mode, defer err
        if err?
          log().error "Failed to change mode of #{parent} to #{mode}: #{err.message}"

    # If all is well and we're in tmp mode, then we need to make this
    # last directory, and fail with code EEXISTS if we fail to make it.
    if not err? and tmp
      dir = path.join parent, nxt
      await fs.mkdir dir, mode, defer err
      log().debug "| making directory #{dir}"
      if err?
        log().error "Failed to make dir #{dir}: #{err.message}"

    log().debug "- Made new #{type} keychain"
    tkr = if err? then null else (new klass dir)
    if tkr? and not err?
      await tkr.post_make defer err
    cb err, tkr

  #----------------------------

  copy_key : (k1, cb) ->
    esc = make_esc cb, "TmpKeyRing::copy_key"
    await k1.load esc defer()
    k2 = k1.copy_to_keyring @
    await k2.save esc defer()
    cb()

  #------

  # The GPG class will call this right before it makes a call to the shell/gpg.
  # Now is our chance to talk about our special keyring
  mutate_args : (gargs) ->
    @_rfb.mutate_args gargs
    log().debug "| Mutate GPG args; new args: #{gargs.args.join(' ')}"

##=======================================================================

class TmpKeyRingBase extends AltKeyRingBase

  #----------------------------

  constructor : (dir) ->
    super dir
    @_nuked = false

  #----------------------------

  @make : (klass, cb) ->
    dir = path.join globals().get_tmp_keyring_dir(), base64u.encode(prng(15))
    AltKeyRingBase.make klass, dir, cb

  #----------------------------

  to_string : () -> "tmp keyring #{@dir}"
  is_temporary : () -> true
  tmp_dir : () -> @dir

  #----------------------------

  nuke : (cb) ->
    unless @_nuked
      log().debug "| nuking temporary kerying: #{@dir}"
      await fs.readdir @dir, defer err, files
      if err?
        log().error "Cannot read dir #{@dir}: #{err.message}"
      else
        for file in files
          fp = path.join(@dir, file)
          await fs.unlink fp, defer e2
          if e2?
            log().warn "Could not remove dir #{fp}: #{e2.message}"
            err = e2
        unless err?
          await fs.rmdir @dir, defer err
          if err?
            log().error "Cannot delete tmp keyring @dir: #{err.message}"
      @_nuked = true
    cb err

##=======================================================================

exports.TmpKeyRing = class TmpKeyRing extends TmpKeyRingBase

  #------

  @make : (cb) -> TmpKeyRingBase.make TmpKeyRing, cb

##=======================================================================

exports.AltKeyRing = class AltKeyRing extends AltKeyRingBase

  @make : (dir, cb) -> AltKeyRingBase.make AltKeyRing, dir, cb, { perm : true }

##=======================================================================

exports.TmpPrimaryKeyRing = class TmpPrimaryKeyRing extends TmpKeyRingBase

  #------

  @make : (cb) -> TmpKeyRingBase.make TmpPrimaryKeyRing, cb

  #------

  make_ring_file_bundle : () ->
    new RingFileBundle { pub_only : true, @dir, primary : true }

  #------

  # The GPG class will call this right before it makes a call to the shell/gpg.
  # Now is our chance to talk about our special keyring
  mutate_args : (gargs) ->
    @_rfb.mutate_args gargs
    prepend = if gargs.list_keys then [ "--no-default-keyring" ]
    else if (h = globals().get_home_dir())
      [
          "--no-default-keyring",
          "--keyring",             path.join(h, "pubring.gpg"),
          "--secret-keyring",      path.join(h, "secring.gpg"),
          "--trustdb-name",        path.join(h, "trustdb.gpg")
      ]
    else []
    gargs.args = prepend.concat gargs.args
    log().debug "| Mutate GPG args; new args: #{gargs.args.join(' ')}"

##=======================================================================

exports.TmpOneShotKeyRing = class TmpOneShotKeyRing extends TmpKeyRing

  @make : (cb) -> TmpKeyRingBase.make TmpOneShotKeyRing, cb

  #---------------

  gpg : (gargs, cb) ->
    gargs.args.unshift "--no-options"
    super gargs, cb

  #---------------

  base_args : () -> [ "--trusted-key", @_key_id_64 ]

  #---------------

  verify_and_decrypt_sig : ({sig}, cb) ->
    args = @base_args().concat [ "--decrypt", "--no-auto-key-locate" ]
    await @gpg { args, stdin : sig, quiet : true }, defer err, out
    cb err, out

  #---------------

  verify_sig_on_file : ({ sig, file }, cb) ->
    args = @base_args().concat [ "--verify", sig, file ]
    await @gpg { args, quiet : true }, defer err
    cb err

##=======================================================================

exports.QuarantinedKeyRing = class QuarantinedKeyRing extends TmpOneShotKeyRing

  @make : (cb) -> TmpKeyRingBase.make QuarantinedKeyRing, cb

  #------------------------

  set_fingerprint : (fp) ->
    @_fingerprint = fp
    @_key_id_64 = fingerprint_to_key_id_64 fp

  #------------------------

  # No need to make a true one-shot keyring if we have a Sequestered key,
  # since there's guaranteed to only have one key there.
  oneshot_verify : ({query, single, sig, file, no_json, keyblock}, cb) ->
    log().debug "+ Quarantined / oneshot verify"
    await @oneshot_verify_2 { ring : @, sig, file, no_json }, defer err, ret
    log().debug "- Quarantined / oneshot verify -> ok! (fp=#{@_fingerprint})"
    cb err, ret, @_fingerprint

##=======================================================================


