dv = require './decrypt_and_verify'
{add_option_dict} = require './argparse'
{env} = require '../env'
{BufferOutStream,BufferInStream} = require('iced-spawn')
{E} = require '../err'

##=======================================================================

exports.Command = class Command extends dv.Command

  #----------

  set_argv : (a) ->
    if (n = a.files.length) > 2
      new E.ArgsError "Expected 1 or 2 files; got #{n}"
    else
      super a

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ ]
      help : "verify a file"
    name = "verify"
    sub = scp.addParser name, opts
    add_option_dict sub, dv.Command.OPTS
    sub.addArgument [ "files" ], { nargs : '*' }
    return opts.aliases.concat [ name ]

  #----------

  do_keypull : (cb) -> cb null
  do_output : (out, cb) -> cb null

  #----------

  patch_gpg_args : (args) ->
    args.push "--verify"

  #----------

  get_files : (args) ->
    if @argv.files?.length
      args.push @argv.files...
      true
    else
      false
      
##=======================================================================
