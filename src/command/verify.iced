dv = require './decrypt_and_verify'
{add_option_dict} = require './argparse'
{env} = require '../env'
{BufferOutStream,BufferInStream} = require('gpg-wrapper')
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
      aliases : [ "vrfy" ]
      help : "verify a file"
    name = "verify"
    sub = scp.addParser name, opts
    add_option_dict sub, dv.Command.OPTS
    sub.addArgument [ "files" ], { nargs : '*' }
    return opts.aliases.concat [ name ]

  #----------

  make_gpg_args : () ->
    args = [ 
      "--verify" , 
      "--with-colons",   
      "--keyid-format", "long", 
      "--keyserver" , env().get_key_server(),
      "--with-fingerprint"
    ]
    args.push( "--keyserver-options", "debug=1")  if env().get_debug()
    args.push( "--output", o ) if (o = @argv.output)?
    gargs = { args }
    gargs.stderr = new BufferOutStream()
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.files?.length
      args.push @argv.files...
    else
      gargs.stdin = process.stdin
      @batch = true
    return gargs

##=======================================================================
