log = require './log'
{env} = require './env'
{E,GE} = require './err'
{keyring} = require 'gpg-wrapper'

##=======================================================================

class GpgKey extends keyring.GpgKey

  #-------------

  # Find the key in the keyring based on fingerprint
  find : (cb) ->
    await super defer err

    err = if not err? then null
    else if (err instanceof GE.NotFoundError)
      new E.NoLocalKeyError (
        if @_is_self then "You don't have a local #{if @_secret then 'secret' else 'public'} key!"
        else "the user #{@username()} doesn't have a local key"
      )
    else if (err instanceof GE.NoFingerprintError)
      new E.NoRemoteKeyError (
        if @_is_self then "You don't have a registered remote key! Try `keybase push`"
        else "the user #{@username()} doesn't have a remote key"
      )
    else err

    cb err

  #-------------

  has_canonical_username : () ->
    em = env().keybase_email()
    all_uids = @all_uids()
    return (em in (e for uid in all_uids when (e = uid?.email)))

  #-------------

  get_ekid : () ->
    return @_ekid

  #-------------

  # Make a single GpgKey object from a User object. Looks through the given gpg
  # keyring for secret keys belonging to the user and picks the first available
  # one.
  @make_secret_from_user : ({user, keyring}, cb) ->
    for key_manager in user.sibkeys
      # Skip NaCl keys.
      if key_manager.get_type() != 'pgp'
        continue
      secret_key_candidate = @_make_from_user_and_material {
        user
        secret: true
        keyring
        bundle: key_manager.armored_pgp_public
        fingerprint : key_manager.get_pgp_fingerprint().toString('hex')
        ekid: key_manager.get_ekid()
      }
      # Check whether key material is available.
      await secret_key_candidate.find defer err
      # If we found the key, return it.
      if not err?
        cb null, secret_key_candidate
        return
      # If not, loop and try the next key.
    # Loop exited without finding a key.
    cb new E.NoLocalKeyError "No GPG secret key available for user #{user.username()}"

  #-------------

  # Makes a public (secret=false) GpgKey object for every key a user has.
  @make_all_public_from_user : ({user, keyring}) ->
    keys = []
    for key_manager in user.sibkeys
      # Skip NaCl keys.
      if key_manager.get_type() != 'pgp'
        continue
      keys.push @_make_from_user_and_material {
        user
        secret: false
        keyring
        bundle: key_manager.armored_pgp_public
        fingerprint : key_manager.get_pgp_fingerprint().toString('hex')
        ekid: key_manager.get_ekid()
      }
    return keys

  #-------------

  # Make a key object from a User object, the supplied PGP bundle, and the
  # supplied PGP fingerprint.
  @_make_from_user_and_material : ({user, secret, keyring, bundle, fingerprint, ekid}) ->
    ret = new GpgKey {
      user : user ,
      secret : secret,
      username : user.username(),
      is_self : user.is_self(),
      uid : user.id,
      key_data : bundle,
      keyring : keyring,
      fingerprint : fingerprint,
    }
    ret._ekid = ekid
    return ret

##=======================================================================

for k,v of keyring
  exports[k] = v

#--------

exports.BaseKeyRing.prototype.make_all_public_gpg_keys_from_user = ({user}) ->
  return GpgKey.make_all_public_from_user { user, keyring : @ }

exports.BaseKeyRing.prototype.make_secret_gpg_key_from_user = ({user}, cb) ->
  return GpgKey.make_secret_from_user { user, keyring : @ }, cb

#--------

# Overwrite init() as follows
exports.init = () ->
  keyring.init {
    get_preserve_tmp_keyring : () -> env().get_preserve_tmp_keyring()
    get_debug : () -> env().get_debug()
    get_tmp_keyring_dir : () -> env().get_tmp_keyring_dir()
    get_key_klass : () -> GpgKey
    get_home_dir : () -> env().get_home_gnupg_dir(true)
    get_gpg_cmd : () -> env().get_gpg_cmd()
    get_no_options : () -> env().get_no_gpg_options()
    log : log
  }

##=======================================================================



