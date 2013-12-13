{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "vers" ]
      help : "output version information about this client"
    name = "version"
    sub = scp.addParser name, opts
    return opts.aliases.concat [ name ]

  #----------
  
  run : (cb) ->
    console.log "hello!"
    cb true

##=======================================================================

