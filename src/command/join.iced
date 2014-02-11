{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{prompt_yn,Prompter} = require '../prompter'
{checkers} = require '../checkers'
{make_esc} = require 'iced-error'
triplesec = require 'triplesec'
{rng} = require 'crypto'
{constants} = require '../constants'
SC = constants.security
req = require '../req'
{env} = require '../env'
read = require 'read'
session = require '../session'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    e : 
      aliases : [ 'email' ]
      help : 'the email address to signup'
    u :
      aliases : [ 'username' ]
      help : 'the username to signup as'

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "signup" ]
      help : "establish a new account on keybase.io"
    name = "join"
    sub = scp.addParser name, opts
    opts.aliases.concat [ name ]

  #----------

  prompt : (cb) ->
    seq =
      username : 
        prompt : "Your desired username"
        checker : checkers.username
      passphrase: 
        prompt : "Your passphrase"
        passphrase: true
        checker: checkers.passphrase
        confirm : 
          prompt : "confirm passphrase"
      email :
        prompt : "Your email"
        checker : checkers.email
      invite:
        prompt : "Invitation code"
        checker : checkers.invite_code
        defval : "123412341234123412341234"

    if not @prompter
      if (u = env().get_username())?   then seq.username.defval   = u
      if (p = env().get_passphrase())? then seq.passphrase.defval = p
      if (e = env().get_email())?      then seq.email.defval      = e
      @prompter = new Prompter seq

    await @prompter.run defer err
    @data = @prompter.data() unless err?
    cb err

  #----------

  gen_pwh : (cb) ->
    passphrase = @data.passphrase
    if not(@pp_last) or (@pp_last isnt passphrase)
      await session.gen_pwh { passphrase }, defer err, @pwh, @salt, @pwh_version
      @pp_last = passphrase if not err?
    cb err

  #----------

  post : (cb) ->
    args =  
      salt : @salt.toString('hex')
      pwh : @pwh.toString('hex')
      username : @data.username
      email : @data.email
      invitation_id : @data.invite
      pwh_version : @pwh_version

    await req.post { endpoint : "signup", args }, defer err, body
    retry = false
    if err? and (err instanceof E.KeybaseError)
      switch body.status.name
        when 'BAD_SIGNUP_EMAIL_TAKEN'
          log.error "Email address '#{@data.email}' already registered"
          retry = true
          @prompter.clear 'email'
          err = null
        when 'BAD_SIGNUP_USERNAME_TAKEN'
          log.error "Username '#{@data.username}' already registered"
          retry = true
          @prompter.clear 'username'
          err = null
        when 'INPUT_ERROR'
          if err.fields.username
            log.error "Username '#{@data.username}' was rejected by the server"
            retry = true
            @prompter.clear 'username'
            err = null

    if not err?       
      @uid = body.uid
      session.set_id body.session
      session.set_csrf body.csrf_token
    else if not retry then log.error "Unexpected error: #{err}"

    cb err, retry

  #----------

  write_out : (cb) ->
    esc = make_esc cb, "Join::write_out"
    await @write_config   esc defer()
    await session.write   esc defer()
    cb null

  #----------

  write_config : (cb) ->
    c = env().config
    c.set "user.email", @data.email
    c.set "user.salt",  @salt.toString('hex')
    c.set "user.name",  @data.username
    c.set "user.id"  ,  @uid
    await c.write defer err
    cb err

  #----------

  check_registered : (cb) ->
    err = null
    if (env().config.get "user.id")?
      opts =
        prompt : "Already registered; do you want to reregister?"
        defval : false
      await prompt_yn opts, defer err, rereg
      if not err? and not rereg
        err = new E.CancelError "registration canceled"
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Join::run"
    retry = true
    await @check_registered esc defer()
    while retry
      await @prompt  esc defer()
      await @gen_pwh esc defer()
      await @post    esc defer retry
    await @write_out esc defer()
    log.info "Success! You are now signed up."
    cb null

##=======================================================================

