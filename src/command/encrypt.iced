{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{gpg,BufferInStream} = require('gpg-wrapper')
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
      help : "output in binary (rather than ASCII/armored)"

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
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file.length is 1
      args.push [ @argv.file[0] ]
    args.push [ "-a" ] unless @argv.binary
    await gpg gargs, defer err, out
    log.console.log out.toString( if @argv.binary then 'utf8' else 'binary' )
    cb err 

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    opts.remote = true if @argv.track_remote
    opts.lcoal = true if @argv.track_local
    @tssc = new TrackSubSubCommand { args : { them : @argv.them[0]}, opts : @argv }
    await @tssc.run esc defer()
    await @do_encrypt esc defer()
    cb null

##=======================================================================

