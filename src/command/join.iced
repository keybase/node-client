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
      aliases : [ "signup" ]
    name = "join"
    sub = scp.addParser name, opts
    opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    log.error "unimplemented"
    cb new E.UnimplementedError, "Feature not implemented"

##=======================================================================

