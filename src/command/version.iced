{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{version_info} = require '../version'

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
    await version_info null, defer err, lines
    if not err? and lines?
      console.log lines.join("\n")
    cb err

##=======================================================================

