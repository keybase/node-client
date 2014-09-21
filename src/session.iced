
{env} = require './env'
req = require './req'
{E} = require './err'
{make_esc} = require 'iced-error'
{Config} = require './config'
{prompt_passphrase,prompt_email_or_username} = require './prompter'
{constants} = require './constants'
SC = constants.security
triplesec = require 'triplesec'
{WordArray} = triplesec
{createHmac} = require 'crypto'
{make_scrypt_progress_hook} = require './util'
log = require './log'

#======================================================================

exports.Session = class Session 

  #-----

  get_passphrase : ({extra, stderr}, cb) ->
    unless @_passphrase?
      err = null
      pp = env().get_passphrase()
      unless pp?
        await prompt_passphrase {extra, short : true , stderr}, defer err, pp
      @_passphrase = pp
    cb err, @_passphrase

  #-----

  clear_passphrase : () ->
    @_passphrase = null

  #-----

  get_email_or_username_i : (cb) ->
    err = null
    username = env().get_username()
    email = env().get_email()
    unless (username? or email?)
      await prompt_email_or_username defer err, {email, username}
      unless err?
         c = env().config
         c.set "user.email", email if email?
         c.set "user.name", username if username?
    cb err, (username or email)

  #-----

  constructor : () ->
    @_file = null
    @_loaded = false
    @_id = null
    @_logged_in = false
    @_salt = null
    @_passphrase = null
    @_load_and_checked = false

  #-----

  load_and_login : (cb) ->
    err = null
    await @load defer  err  unless @_file? and @_loaded
    await @login defer err  unless err?
    cb err

  #-----

  load_and_check : (cb) ->
    esc = make_esc cb, "Session::load_and_check"
    log.debug "+ session::load_and_check"
    ret = null
    if @_load_and_checked
      log.debug "| already loaded and checked"
      ret = @logged_in()
    else
      await @load esc defer() unless @_file? and @_loaded
      li_pre = @logged_in()
      await @check esc defer li_post
      @_load_and_checked = true
      if li_pre and not li_post
        @_file.clear()
        req.clear_session()
        req.clear_csrf()
        await @_file.write esc defer()
      ret = li_post
    log.debug "- session::load_and_check -> #{ret}"
    cb null, ret

  #-----

  load : (cb) ->
    log.debug "+ session::load"
    unless @_file
      @_file = new Config env().get_session_filename(), { quiet : true, secret : true }
    await @_file.open defer err
    if not err? and @_file.found 
      @_loaded = true
      if (o = @_file.obj())?
        if (s = o.session)?
          req.set_session s
          @_id = s
        if (c = o.csrf)?
          req.set_csrf c
          @_csrf = c
    log.debug "- session::load"
    cb err

  #-----

  set_id : (s) ->
    @_id = s
    req.set_session s
    @_file.set "session", s

  #-----

  set_csrf : (c) ->
    @_csrf = c
    req.set_csrf c
    @_file.set "csrf", c

  #-----

  write : (cb) ->
    esc = make_esc cb, "write"
    await @load              esc defer() unless @_loaded
    await @_file.write       esc defer()
    await env().config.write esc defer()
    cb null

  #-----

  gen_pwh : ({passphrase, salt}, cb) ->
    salt or= @_salt
    @enc = new triplesec.Encryptor { 
      key : new Buffer(passphrase, 'utf8')
      version : SC.triplesec.version
    }

    progress_hook = make_scrypt_progress_hook()
    extra_keymaterial = SC.pwh.derived_key_bytes + SC.openpgp.derived_key_bytes
    await @enc.resalt { salt, extra_keymaterial, progress_hook }, defer err, km
    unless err?
      @_salt = @enc.salt.to_buffer()
      @_pwh = km.extra[0...SC.pwh.derived_key_bytes]
      @_pwh_version = triplesec.CURRENT_VERSION
    cb err, @_pwh, @_salt, @_pwh_version

  #-----

  gen_hmac_pwh : ( {passphrase, salt, login_session}, cb) ->
    await @gen_pwh { passphrase, salt }, defer err, pwh
    unless err?
      hmac_pwh = createHmac('SHA512', pwh).update(login_session).digest()
    else
      hmac_pwh = null
    cb err, hmac_pwh

  #-----

  get_id : () -> @_id or @_file?.obj()?.session
  get_uid : () -> @uid

  #-----

  check : (cb) ->
    log.debug "+ session::check"
    if req.get_session() 
      log.debug "| calling to sesscheck"
      await req.get { endpoint : "sesscheck", need_cookie : true }, defer err, body
      if not err? 
        @_logged_in = true
        @uid = body.logged_in_uid
        env().config.set "user.id", body.logged_in_uid
        @username = body.username
        env().config.set "user.name", @username if @username?
        @set_csrf t if (t = body.csrf_token)?
      else if err and (err instanceof E.KeybaseError) and (body?.status?.name is "BAD_SESSION")
        err = null
    log.debug "- session::check"
    cb err, @_logged_in

  #-----

  logout : (cb) ->
    esc = make_esc cb, "logout"
    await @check esc defer()
    if @logged_in()
      await @post_logout esc defer()
    await @_file.unlink esc defer() if @_loaded
    cb null

  #-----

  get_salt : (args, cb) ->
    salt = login_session = null
    await req.get { endpoint : "getsalt", args }, defer err, body
    unless err?
      salt = (new Buffer body.salt, 'hex')
      env().config.set "user.salt", body.salt
      login_session = new Buffer body.login_session, 'base64'
    cb err, salt, login_session

  #-----

  post_logout : (cb) ->
    await req.post { endpoint : "logout" }, defer err
    cb err

  #-----

  post_login : (args, cb) ->
    await req.post { endpoint : "login", args }, defer err, body
    if err?
      @clear_passphrase()
    else
      @set_id body.session
      @set_csrf body.csrf_token
      @uid = body.uid
      @username = body.me.basics.username
      env().config.set "user.id", body.uid
      env().config.set "user.name", @username if @username
      @_logged_in = true
    cb err

  #-----

  login : (cb) ->
    esc = make_esc cb, "login"
    did_login = false
    await @check esc defer()
    if not @logged_in()
      await @get_email_or_username_i esc defer email_or_username
      await @get_passphrase {}, esc defer passphrase
      await @get_salt {email_or_username }, esc defer salt, login_session
      await @gen_hmac_pwh { passphrase, salt, login_session }, esc defer hmac_pwh
      args =  {
        email_or_username,
        hmac_pwh : hmac_pwh.toString('hex'),
        login_session : login_session.toString('base64')
      }
      await @post_login args, esc defer()
      did_login = true
    await @write esc defer()
    cb null, did_login

  #-----

  logged_in : () -> @_logged_in

#======================================================================

exports.session = _session = new Session

for k of Session.prototype
  ((fname) -> exports[fname] = (args...) -> _session[fname] args...)(k)

#======================================================================
