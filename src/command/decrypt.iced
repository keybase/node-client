{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferOutStream,BufferInStream} = require('gpg-wrapper')
{make_esc} = require 'iced-error'
{env} = require '../env'
{TmpPrimaryKeyRing} = require '../keyring'
{TrackSubSubCommand} = require '../tracksubsub'
{athrow} = require('pgp-utils').util

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
    '6' :
      alias : "base64"
      action : "storeTrue"
      help : "output result as base64-encoded data"
    m:
      alias : "message"
      help : "provide the message on the command line"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "dec" ]
      help : "decrypt a file"
    name = "decrypt"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "file" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  handle_signature : (cb) ->
    esc = make_esc cb, "Command::handle_signature"
    opts = 
      remote : @argv.track_remote
      local : @argv.track_local
    await @tmp_keyring.list_keys esc defer ids
    if ids.length is 0
      log.debug "| No new keys imported"
      log.console.error @decrypt_stderr.data().toString('utf8')
    else if ids.length > 1
      await athrow (new E.CorruptionError "Too many imported keys: #{ids.length}"), esc defer()
    else
      ki64 = ids[0]
      log.debug "| Found new key in the keyring: #{ki64}"
      args = { them_ki64 : ki64 }
      @tssc = new TrackSubSubCommand { args, opts, @tmp_keyring }
      await @tssc.run esc defer()
    cb null

  #----------

  do_decrypt : (cb) ->
    args = [ "--decrypt" , "--with-colons", "--keyid-format", "long", "--keyserver" , env().get_key_server() ]
    args.push( "--keyserver-options", "debug=1")  if env().get_debug()
    gargs = { args }
    gargs.stderr = @decrypt_stderr = new BufferOutStream()
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file?
      args.push @argv.file 
    else
      gargs.stdin = process.stdin
    await @tmp_keyring.gpg gargs, defer err, out
    log.console.log out.toString( if @argv.base64 then 'base64' else 'binary' )
    cb err 

  #----------

  setup_tmp_keyring : (cb) ->
    await TmpPrimaryKeyRing.make defer err, @tmp_keyring
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    opts = 
      remote : @argv.track_remote
      local : @argv.track_local
    await @setup_tmp_keyring esc defer()
    await @do_decrypt esc defer()
    await @handle_signature esc defer()
    cb null

##=======================================================================

