
{env} = require './env'
req = require './req'
{E} = require './err'
{make_esc} = require 'iced-error'
{Config} = require './config'
{prompt_passphrase,prompt_email_and_username} = require './prompter'
{constants} = require './constants'
SC = constants.security
triplesec = require 'triplesec'
ProgressBar = require 'progress'

#======================================================================

exports.Session = class Session 

  #-----

  get_passphrase : (cb) ->
    err = null
    pp = env().get_passphrase()
    unless pp?
      await prompt_passphrase defer err, pp
    cb err, pp

  #-----

  get_email_or_username : (cb) ->
    err = null
    username = env().get_username()
    email = env().get_username()
    unless (username? or email?)
      await prompt_email_or_username defer err, {email, username}
      unless err?
         c = env().config
         c.set "user.email", email if email?
         c.set "user.name", name if name?
    cb err, (username or email)

  #-----

  constructor : () ->
    @_file = null
    @_loaded = false
    @_id = null
    @_logged_in = false
    @_salt = null

  #-----

  load : (cb) ->
    unless @_file
      @_file = new Config env().get_session_filename(), { quiet : true }
    await @_file.open defer err
    if not err? and @_file.found 
      @_loaded = true
      if (s = @_file.obj()?.session)?
        req.set_session s
        @_id = s
    cb err

  #-----

  set_id : (s) ->
    @_id = s
    req.set_session s
    @_file.set "session", s

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

    bar = null
    prev = 0
    progress_hook = (obj) ->
      if obj.what isnt "scrypt" then #noop
      else 
        bar or= new ProgressBar "- run scrypt [:bar] :percent", { 
          width : 35, total : obj.total 
        }
        bar.tick(obj.i - prev)
        prev = obj.i

    extra_keymaterial = SC.pwh.derived_key_bytes + SC.openpgp.derived_key_bytes
    await @enc.resalt { salt, extra_keymaterial, progress_hook }, defer err, km
    unless err?
      @_salt = @enc.salt.to_buffer()
      @_pwh = km.extra[0...SC.pwh.derived_key_bytes]
    cb err, @_pwh, @_salt

  #-----

  get_id : () -> @_id or @_file?.obj()?.session

  #-----

  check : (cb) ->
    if req.get_session()
      await req.get { endpoint : "sesscheck" }, defer err, body
      if not err? 
        @_logged_in = true
        env().config.set "user.id", body.uid
      else if err and (err instanceof E.KeybaseError) and (body?.status?.name is "BAD_SESSION")
        err = null
    cb err, @_logged_in

  #-----

  get_salt : (args, cb) ->
    salt = null
    await req.get { endpoint : "getsalt", args }, defer err, body
    unless err?
      salt = (new Buffer body.salt, 'hex')
      env().config.set "user.salt", body.salt
    cb err, salt

  #-----

  post_login : (args, cb) ->
    await req.post { endpoint : "login", args }, defer err, body
    unless err?
      @set_id body.session
      @uid = body.uid
      @_logged_in = true
    cb err

  #-----

  login : (cb) ->
    await @check defer err
    if not @logged_in()
      esc = make_esc cb, "login"
      await @get_email_or_username esc defer email_or_username
      await @get_passphrase esc defer passphrase
      await @get_salt {email_or_username }, esc defer salt
      await @gen_pwh { passphrase, salt }, esc defer pwh
      await @post_login {email_or_username, pwh : pwh.toString('hex') }, esc defer()
      await @write esc defer()
    cb err

  #-----

  logged_in : () -> @_logged_in

#======================================================================

exports.session = _session = new Session

for k of Session.prototype
  ((fname) -> exports[fname] = (args...) -> _session[fname] args...)(k)

#======================================================================
