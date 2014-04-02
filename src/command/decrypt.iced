dv = require './decrypt_and_verify'
{add_option_dict} = require './argparse'
{env} = require '../env'
{BufferOutStream,BufferInStream} = require('iced-spawn')
{TrackSubSubCommand} = require '../tracksubsub'
log = require '../log'
{keypull} = require '../keypull'

##=======================================================================

exports.Command = class Command extends dv.Command

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "dec" ]
      help : "decrypt a file"
    name = "decrypt"
    sub = scp.addParser name, opts
    add_option_dict sub, dv.Command.OPTS
    add_option_dict sub, {
      o:
        alias : "output"
        help : "output to the given file"
    }
    sub.addArgument [ "file" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  do_output : (out, cb) ->
    if @argv.base64
      log.console.log out.toString('base64')
    else
      await process.stdout.write out, defer()
    cb()

  #----------

  is_batch : () -> not(@argv.message?) and not(@argv.file?)

  #----------

  do_keypull : (cb) ->
    await keypull {stdin_blocked : @is_batch(), need_secret : true }, defer err
    @_ran_keypull = true
    cb err

  #----------

  patch_gpg_args : (args) ->
    # 'yes' needed in the case of overwrite!
    args.push("--decrypt", "--yes")

  #----------

  get_files : (args) ->
    if (f = @argv.file)?
      args.push f
      true
    else
      false

##=======================================================================
