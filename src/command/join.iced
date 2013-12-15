{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{Prompter} = require '../prompter'
{checkers} = require '../checkers'
{make_esc} = require 'iced-error'
triplesec = require 'triplesec'
{rng} = require 'crypto'
{constants} = require '../constants'
SC = constants.security
ProgressBar = require 'progress'
req = require '../req'
{env} = require '../env'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    e : 
      aliases : [ 'email' ]
      help : 'the email address to signup'
    u :
      aliase : [ 'username' ]
      help : 'the username to signup as'

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "signup" ]
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

    if not(@pw_last) or (@pw_last isnt @data.passphrase)

      @enc = new triplesec.Encryptor { 
        key : new Buffer(@data.passphrase, 'utf8')
        verion : SC.triplesec.version
      }
      @pw_last = @data.passphrase

      bar = null
      prev = 0
      progress_hook = (obj) ->
        if obj.what isnt "scrypt" then #noop
        else 
          bar or= new ProgressBar "Scrypt [:bar] :percent", { 
            width : 35, total : obj.total 
          }
          bar.tick(obj.i - prev)
          prev = obj.i

      extra_keymaterial = SC.pwh.derived_key_bytes + SC.openpgp.derived_key_bytes
      await @enc.resalt { extra_keymaterial, progress_hook }, defer err, km
      unless err?
        @salt = @enc.salt.to_hex()
        @pwh = km.extra[0...SC.pwh.derived_key_bytes].toString('hex')

    cb err

  #----------

  post : (cb) ->
    args =  
      salt : @salt
      pwh : @pwh
      username : @data.username
      email : @data.email
      invitation_id : @data.invite

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

    if not err?       then @uid = body.uid
    else if not retry then log.error "Unexpected error: #{err}"

    cb err, retry

  #----------

  write_out : (cb) ->
    c = env().config
    c.set "user.email", @data.email
    c.set "user.salt",  @salt
    c.set "user.name",  @data.username
    c.set "user.id"  ,  @uid
    await c.write defer err
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Join::run"
    retry = true
    while retry
      await @prompt  esc defer()
      await @gen_pwh esc defer()
      await @post    esc defer retry
    await @write_out esc defer()
    cb null

##=======================================================================

