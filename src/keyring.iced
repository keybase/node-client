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

  # Make a key object from a User object
  @make_from_user : ({user, secret, keyring}) ->
    new GpgKey {
      user : user ,
      secret : secret,
      username : user.username(),
      is_self : user.is_self(),
      uid : user.id,
      key_data : user?.public_keys?.primary?.bundle,
      keyring : keyring,
      fingerprint : user.fingerprint(true)
    }

##=======================================================================

for k,v of keyring
  exports[k] = v

#--------

exports.BaseKeyRing.prototype.make_key_from_user = (user, secret) ->
  return GpgKey.make_from_user { user, secret, keyring : @ }

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
    log : log
  }

##=======================================================================



