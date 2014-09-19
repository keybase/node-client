{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : TrackSubSubCommand.OPTS

  #----------

  needs_configuration : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts =
      aliases : [ ]
      help : "verify a user's authenticity and optionally track them"
    name = "track"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "them" ], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    tssc = new TrackSubSubCommand { args : { them : @argv.them[0]}, opts : @argv }
    await tssc.run defer err
    log.info 'Success!' unless err?
    cb err

##=======================================================================

