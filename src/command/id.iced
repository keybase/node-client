{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    a :
      action : 'append'
      alias : "assert"
      help : "provide a key assertion"

  #----------------------

  constructor : ({@args, @opts, @tmp_keyring, @batch, @track_local, @ran_keypull}) ->
    @opts or= {}
    @qring = null

  #----------------------

  is_batch : () -> @opts.batch or @batch

  #----------------------

  prompt_ok : (warnings, proofs, cb) ->
    them = @args.them
    prompt = if warnings
      log.console.error colors.red "Some remote proofs failed!"
      "Still verify this user as #{them}?"
    else if proofs is 0
      "We found an account for #{them}, but they haven't proved their identity. Still accept them?"
    else
      "Is this the #{them} you wanted?"
    await prompt_yn { prompt, defval : false }, defer err, ret
    cb err, ret

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "identify" ]
      help : "Identify a user, but don't accept or reject trust"
    name = "id"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "them" ], { nargs : 1, help : "the username to id" }
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    tssc = new TrackSubSubCommand { args : { them : @argv.them[0]} , opts : @argv }
    await tssc.id defer err
    cb err

##=======================================================================

