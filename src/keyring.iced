
{db} = require './db'
{gpg} = require './gpg'
log = require './log'
{constants} = require './constants'
{make_esc} = require 'iced-error'
mkdirp = require 'mkdirp'
{env} = require './env'
{prng} = require 'crypto'
{base64u} = require('pgp-utils').util
path = require 'path'
fs = require 'fs'

##=======================================================================

exports.clean_key_imports = (cb) ->
  esc = make_esc cb, "clean_key_imports"
  log.debug "+ clean key imports"
  state = constants.import_state.TEMPORARY
  await db.select_key_imports_by_state state, esc defer keys
  log.debug "| queried for temp keys, got: #{JSON.stringify keys}"
  if keys.length
    args = [ "--batch", "--delete-keys" ].concat(k.toUpperCase() for k in keys)
    log.debug "| calling GPG client with #{JSON.stringify args}"  
    await gpg { args, tmp : true }, defer err
    state = constants.import_state.CANCELED
    await db.batch_update_key_import { fingerprints : keys, state }, esc defer()
  log.debug "- clean key imports"
  cb null

##=======================================================================

class GpgKey 

  constructor : (fields) ->
    for k,v of fields
      @["_#{k}"] = v

  # The fingerprint of the key
  fingerprint : () -> 

  # The 64-bit GPG key ID
  key_id_64 : () -> @fingerprint()[-16...]

  # The full PGP-style username of the key
  userid : () ->

  # The keybase username of the keyholder
  username : () ->

  # The keybase UID of the keyholder
  uid : () ->

  # These two functions are to fulfill to key manager interface
  get_pgp_key_id : () -> @key_id_64()
  get_pgp_finterprint : () -> @fingerprint()

  # Find the key in the keyring based on fingerprint
  find : (cb) ->

  # Check that this key has been signed by the signing key.
  check_sig : (signing_key, cb) ->

  #-------------

  to_string : () -> [ @username(), @key_id_64 ].join "/"

  #-------------

  gpg : (gargs, cb) -> @keyring.gpg gargs, cb

  #-------------

  # Save this key to the underlying GPG keyring
  save : (cb) ->
    args = [ "--import" ]
    log.debug "| Save key #{@to_string()} to #{@keyring.to_string()}"
    await @gpg { args, stdin : @_key_data, quiet : true }, defer err
    cb err

  #-------------

  # Load this key from the underlying GPG keyring
  load : (cb) ->
    args = [ 
      (if @_secret then "--export-secret-key" else "--secret" ),
      "--export-local-sigs", 
      "-a",
      @fingerprint()
    ]
    log.debug "| Load key #{@to_string()} from #{@keyring.to_string()}"
    await @gpg { args }, defer err, @_key_data
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
    log.debug "| Delete key #{@to_string()} from #{@keyring.to_string()}"
    await @gpg { args }, defer err
    cb err

  #-------------

  # Make a key object from a User object
  @make_from_user : ({user, secret, keyring}) ->
    new GpgKey {
      user : user ,
      secret : secret,
      username : user.username(),
      is_self : user.is_self(),
      secret : false,
      uid : user.id
      key_data : user?.public_keys?.primary?.bundle,
      keyring : keyring
    }

  #-------------

  copy_to_keyring : (keyring) ->
    d = {}
    d[k[1...]] = v for k,v of @ when k[0] is '_'
    ret = new GpgKey d
    ret.keyring = keyring
    return ret

##=======================================================================

exports.BaseKeyRing = class BaseKeyRing extends GPG

  constructor : () ->

  make_key : (opts) ->
    opts.keyring = @
    return new GpgKey opts

  make_key_from_user : (user, secret) ->
    return GpgKey.make_from_user { user, secret, keyring : @ }

##=======================================================================

exports.MasterKeyRing = class MasterKeyRing extends BaseKeyRing

  to_string : () -> "master keyring"

##=======================================================================

_mring = new MasterKeyRing()
exports.master_ring = () -> _mring

##=======================================================================

exports.TmpKeyRing = class TmpKeyRing extends BaseKeyRing

  constructor : (@dir) ->

  #------

  to_string : () -> "tmp keyring #{@dir}"

  #------

  mkfile : (n) -> path.join @dir, n

  #------

  # The GPG class will call this right before it makes a call to the shell/gpg.
  # Now is our chance to talk about our special keyring
  mutate_args : (gargs) ->
    gargs.args = [
      "--no-default-keyring",
      "--keyring",            @mkfile("pub.ring"),
      "--secret-keyring",     @mkfile("sec.ring"),
      "--trustdb-name",       @mkfile("trust.db")
    ].concat gargs.args
    log.debug "| Mutate GPG args; new args: #{gargs.inargs.join(' ')}"

  #------

  gpg : (gargs, cb) ->
    log.debug "| Call to gpg: #{util.inspect(inargs)}"
    gargs.quiet = false if gargs.quiet and env().get_debug()
    await @run gargs, defer err, res
    cb err, res

  #------

  @make : (cb) ->
    mode = 0o700
    parent = env().get_tmp_keyring_dir()
    await mkdirp parent, mode, defer err, made
    if err?
      log.error "Error making tmp keyring dir #{parent}: #{err.message}"
    else if made
      log.info "Creating tmp keyring dir: #{parent}"
    else
      await fs.stat parent, defer err, so
      if err?
        log.error "Failed to stat directory #{parent}: #{err.message}"
      else if (so.mode & 0o777) isnt mode
        await fs.chmod dir, mode, defer err
        if err?
          log.error "Failed to change mode of #{parent} to #{mode}: #{err.message}"

    unless err?
      nxt = base64u.encode prng 12
      dir = path.join parent, nxt
      await fs.mkdir dir, mode, defer err
      log.debug "| making directory #{dir}"
      if err?
        log.error "Failed to make dir #{dir}: #{err.message}"

    tkr = if err? then null else (new TmpKeyRing dir)
    cb err, tkr

  #----------------------------

  copy_key : (k1, cb) ->
    esc = make_esc cb, "TmpKeyRing::copy_key"
    await k1.load defer esc defer()
    k2 = k1.copy_to_keyring @
    await k2.save defer esc defer()
    cb()

  #----------------------------

  nuke : (cb) ->
    await fs.readdir @dir, defer err, files
    if err?
      log.error "Cannot read dir #{@dir}: #{err.message}"
    else 
      for file in files
        fp = path.join(@dir, file)
        await fs.unlink fp, defer e2
        if e2?
          log.warn "Could not remove dir #{fp}: #{e2.message}"
          err = e2
      unless err?
        await fs.rmdir @dir, defer err
        if err?
          log.error "Cannot delete tmp keyring @dir: #{err.message}"
    cb err

##=======================================================================

