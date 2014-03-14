{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{make_esc} = require 'iced-error'
{dict_union} = require '../util'
{User} = require '../user'
{env} = require '../env'
{session} = require '../session'
req = require '../req'
ee = require './encrypt_and_email'

##=======================================================================

exports.Command = class Command extends ee.Command

  #----------

  OPTS : dict_union ee.Command.OPTS, {
    S:
      alias : "no-sign"
      action : "storeTrue"
      help : "don't sign (sign by default)"
    j :
      alias : "subject"
      help : "provide a **CLEARTEXT** subject for the mail"
  }

  #----------

  get_cmd_desc : () ->
    return {
      opts :
        aliases :  [ "em" ]
        help : "encrypt message and send an email (via keybase.io's server)"
      name : "email"
    }

  #----------

  do_sign : () -> not(@argv.no_sign)

  #----------

  subject : () -> 
    j = @argv.subject 
    j = "<An encrypted message via keybase.io>" unless j?
    return j

  #----------

  do_output : (out, cb) ->
    arg =
      endpoint : "email/proxy"
      args : 
        username : @argv.them[0]
        body : out.toString('utf8')
        subject : @subject()
    await req.post arg, defer err, body
    cb err

  #----------

  pre_check : (cb) ->
    esc = make_esc cb, "Command::pre_check"
    await session.load_and_login esc defer()
    arg =
      endpoint : "email/check"
      args :
        username : @argv.them[0]
        notify_on_fail : 1
    await req.get arg, esc defer body
    cb null

##=======================================================================

