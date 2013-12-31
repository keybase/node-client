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
      aliases : [ ]
      help : "display help"
    name = "help"
    sub = scp.addParser name, opts
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    @parent.ap.printHelp()
    cb null

##=======================================================================

