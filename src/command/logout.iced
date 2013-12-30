{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{session} = require '../session'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------


  add_subcommand_parser : (scp) ->
    opts = 
      help : "logout from the server"
    name = "logout"
    sub = scp.addParser name, opts
    return [ name ]

  #----------

  run : (cb) ->
    await session.logout defer err
    cb err

##=======================================================================

