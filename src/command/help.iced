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
    sub.addArgument [ "cmd" ], { nargs : '?', help : "the subcommand you want help with" }
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    if (c = @argv.cmd)?
      if (p = @parent.lookup_parser(c))? then p.printHelp()
      else log.error "Command '#{c}' isn't known"
    else
      @parent.ap.printHelp()
    cb null

##=======================================================================

