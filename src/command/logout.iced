{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "logout from the server"
    name = "logout"
    sub = scp.addParser name, opts
    return [ name ]

  #----------

  run : (cb) ->
    cb new E.UnimplementedError, "not implemented"

##=======================================================================

