{session} = require './session'
{chain_err,make_esc} = require 'iced-error'
{env} = require './env'
log = require './log'
{User} = require './user'
req = require './req'
{KeyManager} = require './keymanager'
{E} = require './err'
{TmpKeyRing,master_ring} = require './keyring'
{prompt_yn} = require './prompter'
colors = require './colors'
{format_fingerprint,athrow} = require('pgp-utils').util

##=======================================================================

PullTypes =
  ERROR : -1
  NONE : 0
  SECRET : 1
  PUBLIC : 2

##=======================================================================

exports.KeyPull = class KeyPull

  #----------

  constructor : ({@force, @stdin_blocked, @need_secret}) ->

  #----------

  secret_pull : (cb) ->
    log.debug "+ KeyPull::secret_pull"
    esc = make_esc cb, "KeyPull::secret_pull"

    if not (p3skb = @me.private_key_bundle())?
      err = new E.NoLocalKeyError "couldn't find a private key bundle for you"
    else
      err = null
      passphrase = null
      args = 
        extra : " (to pull your private key from the server)"
        stderr : true
      prompter = (cb) =>
        await session.get_passphrase args, defer err, passphrase
        cb err, passphrase
      await KeyManager.import_from_p3skb { raw : p3skb, prompter }, esc defer km
      await km.save_to_ring { passphrase }, esc defer()
      log.info "Pulled secret key (#{format_fingerprint @me.fingerprint(true)})"

    log.debug "- KeyPull::secret_pull"
    cb err

  #----------

  load_user : (cb) ->
    log.debug "+ KeyPull::load_user"
    esc = make_esc cb, "KeyPull::load_user"

    await User.load { username : env().get_username(), require_public_key : false, cache : true, self : true, secret : true }, esc defer @me
    await @me.check_key { secret : true  }, esc defer sec
    await @me.check_key { secret : false }, esc defer pub
    log.debug "Check key secret: #{JSON.stringify sec}"
    log.debug "Check key public: #{JSON.stringify pub}"

    err = null

    pull_needed = if not pub.remote
      err = new E.NoRemoteKeyError "you don't have a public key; try `keybase push` if you have a key; or `keybase gen` if you don't"
      PullTypes.ERROR
    else if sec.remote and not(sec.local) and @need_secret then PullTypes.SECRET
    else if @need_secret and not(sec.local)
      err = new E.NoRemoteKeyError "can't perform secret-key action without a secret key"
      PullTypes.ERROR
    else if pub.local and (not(sec.remote) or sec.local) and not(@force) then PullTypes.NONE
    else if sec.remote and (not(sec.local) or @force) then PullTypes.SECRET
    else PullTypes.PUBLIC

    log.debug "- KeyPull::load_user -> #{err} #{pull_needed}"
    cb err, pull_needed

  #---------------------

  prompt_ok : (warnings, proofs, cb) ->
    prompt = if warnings > 0
      log.console.error colors.red colors.bold "Some of your hosted proofs failed!"
      "Do you still accept these credentials to be your own?"
    else if proofs is 0
      "We found your account, but you have no hosted proofs. Check your fingerprint carefully. Is this you?"
    else
      "Is this you?"
    await prompt_yn { prompt, defval : false }, defer err, ret
    if not(ret) and not(err?)
      err = new E.CancelError "key import operation canceled"
    cb err

  #---------------------

  public_pull : (cb) ->
    tmp_keyring = null

    log.debug "+ KeyPull::public_pull"

    cb = chain_err cb, (tcb) ->
      if tmp_keyring?
        await tmp_keyring.nuke defer e2
        log.warn "Problem in cleanup: #{e2.message}" if e2?
      tcb null

    esc = make_esc cb, "KeyPull::public_pull"
    await TmpKeyRing.make esc defer tmp_keyring
    await @me.import_public_keys { keyring : tmp_keyring }, esc defer()
    await @me.check_remote_proofs {}, esc defer warnings, n_proofs
    await @prompt_ok warnings.warnings().length, n_proofs, esc defer()
    for key in @me.gpg_keys
      await key.commit {}, esc defer()
      log.info "Pulled public key (#{format_fingerprint key.fingerprint().toString('hex').toUpperCase()})"
    log.debug "- KeyPull::public_pull"
    cb null

  #---------------------
  
  run : (cb) ->
    esc = make_esc cb, "Command::run"
    log.debug "+ KeyPull::run"
    await @load_user esc defer pull_type
    if (pull_type isnt PullTypes.NONE) and @stdin_blocked
      err = new E.NoLocalKeyError "Can't fetch your private key since you're performing a stream action; try an explicit `keybase pull`"
      await athrow err, esc defer()
    switch pull_type
      when PullTypes.SECRET
        await @secret_pull esc defer()
      when PullTypes.PUBLIC
        await @public_pull esc defer()
    log.debug "- KeyPull::run"
    cb null

##=======================================================================

exports.keypull = (opts, cb) ->
  kp = new KeyPull opts
  await kp.run defer err
  cb err

##=======================================================================

