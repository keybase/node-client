dv = require './decrypt_and_verify'
{add_option_dict} = require './argparse'
{env} = require '../env'
{BufferOutStream,BufferInStream} = require('gpg-wrapper')

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

  do_output : (o) ->
    log.console.log out.toString( if @argv.base64 then 'base64' else 'binary' )

  #----------
  
  make_gpg_args : () ->
    args = [ 
      "--decrypt" , 
      "--with-colons",   
      "--keyid-format", "long", 
      "--keyserver" , env().get_key_server(),
      "--with-fingerprint"
      "--yes" # needed in the case of overwrite!
    ]
    args.push( "--keyserver-options", "debug=1")  if env().get_debug()
    args.push( "--output", o ) if (o = @argv.output)?
    gargs = { args }
    gargs.stderr = new BufferOutStream()
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file?
      args.push @argv.file 
    else
      gargs.stdin = process.stdin
    return gargs

##=======================================================================
