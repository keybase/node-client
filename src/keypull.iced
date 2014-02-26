{session} = require './session'
{make_esc} = require 'iced-error'
{env} = require './env'
log = require './log'
{User} = require './user'
req = require './req'
{KeyManager} = require './keymanager'
{E} = require './err'
{master_ring} = require './keyring'

##=======================================================================

exports.KeyPull = class KeyPull

  #----------

  constructor : ({@force}) ->

  #----------

  get_private_key : (cb) ->
    log.debug "+ Fetching me.json from server"
    await req.get { endpoint : "me" }, defer err, body
    if not err? and not (@p3skb = body.me.private_keys?.primary?.bundle)?
      err = new E.NoRemoteKeyError "no private key found on server"
    log.debug "- fetched me"
    cb err

  #----------

  prompt_passphrase : (cb) ->
    await session.get_passphrase defer err, @passphrase
    cb err, @passphrase

  #----------

  unlock_key : (cb) ->
    prompter = @prompt_passphrase.bind(@)
    await KeyManager.import_from_p3skb { raw : @p3skb, prompter }, defer err, @km
    cb err

  #----------

  save : (cb) ->  
    await @km.save_to_ring { @passphrase }, defer err
    cb err

  #----------

  check_key_exists : (cb) ->
    log.debug "+ KeyPull::check_key_exists"
    esc = make_esc cb, "KeyPull::check_key_exists"
    await User.load_me { secret : false, install_key : true }, esc defer @me
    key = master_ring().make_key_from_user @me, true
    await key.find defer err
    fp = @me.fingerprint(true)
    if err? and (err instanceof E.NoLocalKeyError)
      found = false
      log.debug "Couldn't find secret key w/ fingerprint #{fp}" if @force
    else if not err?
      found = true
      log.info "Will overwrite existing secret key w/ fingerprint #{fp}" if @force
    log.debug "- KeyPull::check_key_exists -> #{found}"
    cb err, found

  #----------
  
  run : (cb) ->
    esc = make_esc cb, "Command::run"
    log.debug "+ KeyPull::run"
    await @check_key_exists esc defer skip
    skip = false if @force
    unless skip
      await @get_private_key esc defer()
      await @unlock_key esc defer()
      await @save esc defer()
    log.debug "- KeyPull::run"
    cb null

##=======================================================================

