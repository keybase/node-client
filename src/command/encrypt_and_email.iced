{Base} = require './base'
log = require '../log'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferInStream} = require('iced-spawn')
{master_ring} = require '../keyring'
{make_esc} = require 'iced-error'
{User} = require '../user'
{env} = require '../env'
{dict_union} = require '../util'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  @OPTS : dict_union TrackSubSubCommand.OPTS, {
    m:
      alias : "message"
      help : "provide the message on the command line"   
  }

  #----------

  add_subcommand_parser : (scp) ->
    { opts, name } = @get_cmd_desc()
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "them" ], { nargs : 1 , help : "the username of the receiver" }
    sub.addArgument [ "file" ], { nargs : '?', help : "the file to be encrypted" }
    return opts.aliases.concat [ name ]

  #----------

  output_file : () -> null
  do_binary : () -> false

  #----------

  do_encrypt : (cb) ->
    tp = @them.fingerprint true
    args = [ 
      "--encrypt", 
      "-r", tp,
      "--trust-mode", "always"
    ]
    if @do_sign()
      sign_key = if @is_self then @them else @tssc.me
      args.push( "--sign", "-u", (sign_key.fingerprint true) )
    gargs = { args }
    gargs.quiet = true
    args.push("--output", o, "--yes") if (o = @output_file())
    args.push "-a"  unless @do_binary()
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file?
      args.push @argv.file 
    else
      gargs.stdin = process.stdin
    await master_ring().gpg gargs, defer err, out
    unless err?
      await @do_output out, defer err
    cb err 

  #----------

  pre_check : (cb) -> cb null

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @pre_check esc defer()
    batch = (not @argv.message and not @argv.file?)
    them_un = @argv.them[0]
    if them_un is env().get_username()
      @is_self = true
      await User.load_me { secret : true }, esc defer @them
    else
      @is_self = false
      @tssc = new TrackSubSubCommand { args : { them : them_un }, opts : @argv, batch }
      await @tssc.run esc defer()
      @them = @tssc.them
    await @do_encrypt esc defer()
    cb null

##=======================================================================

