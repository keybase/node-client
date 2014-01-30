{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferInStream} = require('gpg-wrapper')
{master_ring} = require '../keyring'
{make_esc} = require 'iced-error'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    r :
      alias : "track-remote"
      action : "storeTrue"
      help : "remotely track by default"
    l : 
      alias : "track-local"
      action : "storeTrue"
      help : "don't prompt for remote tracking"
    s:
      alias : "sign"
      action : "storeTrue"
      help : "sign in addition to encrypting"
    m:
      alias : "message"
      help : "provide the message on the command line"
    b :
      alias : 'binary'
      action: "storeTrue"
      help : "output in binary (rather than ASCII/armored)"
    o :
      alias : 'output'
      help : 'the output file to write the encryption to'

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "enc" ]
      help : "verify a user's authenticity and optionally track him"
    name = "encrypt"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "them" ], { nargs : 1 }
    sub.addArgument [ "file" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  do_encrypt : (cb) ->
    args = [ "--encrypt", "-r", (@tssc.them.fingerprint true) ]
    args.push( "--sign", "-u", (@tssc.me.fingerprint true) ) if @argv.sign
    gargs = { args }
    args.push("--output", o, "--yes") if (o = @argv.output)
    args.push "-a"  unless @argv.binary
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file?
      args.push @argv.file 
    else
      gargs.stdin = process.stdin
    await master_ring().gpg gargs, defer err, out
    unless @argv.output?
      log.console.log out.toString( if @argv.binary then 'utf8' else 'binary' )
    cb err 

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    opts = 
      remote : @argv.track_remote
      local : @argv.track_local
    @tssc = new TrackSubSubCommand { args : { them : @argv.them[0]}, opts }
    await @tssc.run esc defer()
    await @do_encrypt esc defer()
    cb null

##=======================================================================

