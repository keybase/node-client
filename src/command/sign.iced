{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferInStream} = require('iced-spawn')
{gpg} = require '../gpg'
{make_esc} = require 'iced-error'
{User} = require '../user'
{keypull} = require '../keypull'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    m:
      alias : "message"
      help : "provide the message on the command line"
    b :
      alias : 'binary'
      action: "storeTrue"
      help : "output in binary (rather than ASCII/armored)"
    'clearsign':
      action : 'storeTrue'
      help : "make a clear signature"
    'detach-sign':
      action : 'storeTrue'
      help : "make a detached signature"
    o :
      alias : 'output'
      help : 'specify an output file'

  #----------

  is_batch : () -> not(@argv.message?) and not(@argv.file?)

  #----------

  set_argv : (a) ->
    if a.clearsign and a.detach_sign
      new E.ArgsError "Can only handle one of --clearsign and --detach-sign"
    else
      super a

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "sig" ]
      help : "sign a message"
    name = "sign"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "file" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  do_sign : (cb) ->
    args = [ "--sign", "-u", (@me.fingerprint true) ]
    gargs = { args }
    args.push "-a"  unless @argv.binary
    args.push "--clearsign" if @argv.clearsign
    args.push "--detach-sign" if @argv.detach_sign
    args.push("--output", o ) if (o = @argv.output)?
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file?
      args.push @argv.file 
    else
      gargs.stdin = process.stdin
    await gpg gargs, defer err, out
    unless @argv.output
      log.console.log out.toString( if @argv.binary then 'utf8' else 'binary' )
    cb err 

  #----------

  load_me : (cb) ->
    await User.load_me {secret : true}, defer err, @me
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    log.debug "+ Command::run"
    await keypull { stdin_blocked : @is_batch(), need_secret : true }, esc defer()
    await @load_me esc defer()
    await @do_sign esc defer()
    log.debug "- Command::run"
    cb null

##=======================================================================

