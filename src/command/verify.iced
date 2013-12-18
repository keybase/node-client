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
      aliases : [ "vrfy" ]
      help : "add a proof of identity"
    name = "verify"
    sub = scp.addParser name, opts
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    cb new E.UnimplementedError "feature not implemented"

##=======================================================================

