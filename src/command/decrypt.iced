{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferOutStream,BufferInStream} = require('gpg-wrapper')
{make_esc} = require 'iced-error'
{env} = require '../env'
{TmpPrimaryKeyRing} = require '../keyring'

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

  handle_signature : (stderr, cb) ->
    esc = make_esc cb, "Command::handle_signature"
    await @tmp_keyring.list_keys esc defer ids
    if ids.length > 0
      log.debug "| Found key(s) in the keyring: #{JSON.stringify ids}"
    cb null

  #----------

  do_decrypt : (cb) ->
    args = [ "--decrypt" , "--with-colons", "--keyid-format", "long", "--keyserver" , env().get_key_server() ]
    args.push( "--keyserver-options", "debug=1")  if env().get_debug()
    gargs = { args }
    gargs.stderr = new BufferOutStream()
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file?
      args.push @argv.file 
    else
      gargs.stdin = process.stdin
    await @tmp_keyring.gpg gargs, defer err, out
    log.console.log out.toString( if @argv.base64 then 'base64' else 'binary' )
    unless err?
      await @handle_signature gargs.stderr, defer err
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
    cb null

##=======================================================================

