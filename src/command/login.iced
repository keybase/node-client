{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{session} = require '../session'
{KeyPull} = require '../keypull'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    P:
      alias : "no-key-pull"
      action: "storeTrue"
      help : "don't pull secret key from server"

  #----------

  use_session : () -> true
  needs_cookies : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "establish a session"
    name = "login"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ]

  #----------

  run : (cb) ->
    await session.login defer err
    if not(err?) and not(@argv.no_key_pull)
      kp = new KeyPull { force : false }
      await kp.run defer err
    cb err

##=======================================================================

