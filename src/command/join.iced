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
{dict_union} = require '../util'

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
      email :
        prompt : "Your email"
        checker : checkers.email
      invite:
        prompt : "Invitation code (leave blank if you don't have one)"
        thrower : (k,s) -> if (s.match /^\s*$/)? then (new E.CleanCancelError(k)) else null
      username :
        prompt : "Your desired username"
        checker : checkers.username
      passphrase:
        prompt: "Your login passphrase"
        passphrase: true
        checker: checkers.passphrase
        confirm :
          prompt: "Repeat to confirm"

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
        when 'BAD_INVITATION_CODE'
          log.error "Bad invitation code '#{@data.invite}' given"
          retry = true
          @prompter.clear 'invite'
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

  request_invite : (cb) ->
    esc = make_esc cb, "request_invite"
    await @ri_prompt_for_ok esc defer()
    await @ri_prompt_for_data esc defer d2
    await @ri_post_request d2, esc defer()
    cb null

  #----------

  ri_prompt_for_ok : (cb) ->
    opts =
      prompt : "Would you like to be added to the invite list?"
      defval : true
    await prompt_yn opts, defer err, go
    if not err? and not go
      err = new E.CancelError "invitation request canceled"
    cb err

  #----------

  ri_prompt_for_data : (cb) ->
    seq =
      full_name :
        prompt : "Your name"
      notes :
        prompt : "Any comments for the team"
    prompter = new Prompter seq
    await prompter.run defer err
    ret = null
    ret = prompter.data() unless err?
    cb err, ret

  #----------

  ri_post_request : (d2, cb) ->
    args = dict_union d2, @prompter.data()
    await req.post {endpoint : "invitation_request", args }, defer err
    unless err?
      log.info "Success! You're on our list. Thanks for your interest!"
    cb err

  #----------

  run : (cb) ->
    await @run2 defer err
    if err? and (err instanceof E.CleanCancelError)
      await @request_invite defer err
    cb err

  #----------

  run2 : (cb) ->
    esc = make_esc cb, "Join::run"
    retry = true
    await @check_registered esc defer()
    while retry
      await @prompt  esc defer()
      await @gen_pwh esc defer()
      await @post    esc defer retry
    await @write_out esc defer()
    log.info "Success! You are now signed up."

    log.console.log """

Welcome to keybase.io! You now need to associate a public key with your
account.  If you have a key already then:

    keybase push <key-id>  # if you know the ID of the key --- OR ---
    keybase push           # to select from a menu

If you need a public key, we'll happily generate one for you:

    keybase gen --push     # Generate a new key and push public part to server

Enjoy!
"""
    cb null

##=======================================================================
