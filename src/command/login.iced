{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{session} = require '../session'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "establish a session"
    name = "login"
    sub = scp.addParser name, opts
    return [ name ]

  #----------

  run : (cb) ->
    await session.login defer err
    cb err

##=======================================================================

