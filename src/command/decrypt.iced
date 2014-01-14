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
{parse_signature} = require '../gpg'
colors = require 'colors'
{constants} = require '../constants'
{User} = require '../user'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    s : 
      alias : 'signed'
      action : 'storeTrue'
      help : "assert signed"
    S :
      alias : 'signed-by'
      help : "assert signed by the given user"
    t :
      alias : "track"
      action : "storeTrue"
      help : "prompt for tracking if necessary"
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
    o:
      alias : "output"
      help : "output to the given file"

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

  try_track : () -> @argv.track or @argv.track_remote or @argv.track_local

  #----------

  handle_signature : (cb) ->
    
    [err, @signing_key] = parse_signature @decrypt_stderr.data().toString('utf8')
    @found_sig = not err?

    if (err instanceof E.NotFoundError) and not @argv.signed and not @argv.signed_by?
      log.debug "| No signatured found; but we didn't require one"
      err = null

    if @found_sig
      arg = 
        type : constants.lookups.key_fingerprint_to_user
        name : @signing_key.primary
      await User.map_key_to_user arg, defer err, basics
      unless err?
        log.info "Valid signature from keybase user " + colors.bold(basics.username)
        @username = basics.username
        if (a = @argv.signed_by)? and (a isnt (b = @username))
          err = new E.WrongSignerError "Wrong signer: wanted '#{a}' but got '#{b}'"
    cb err

  #----------

  handle_track : (cb) ->
    esc = make_esc cb, "Command::handle_signature"
    opts = 
      remote : @argv.track_remote
      local : @argv.track_local
    await @tmp_keyring.list_keys esc defer ids
    if ids.length is 0
      log.debug "| No new keys imported"
    else if ids.length > 1
      await athrow (new E.CorruptionError "Too many imported keys: #{ids.length}"), esc defer()
    else
      ki64 = ids[0]
      log.debug "| Found new key in the keyring: #{ki64}"
      args = { them : @username }
      @tssc = new TrackSubSubCommand { args, opts, @tmp_keyring }
      await @tssc.run esc defer()
    cb null

  #----------

  do_decrypt : (cb) ->
    args = [ 
      "--decrypt" , 
      "--with-colons",   
      "--keyid-format", "long", 
      "--keyserver" , env().get_key_server(),
      "--with-fingerprint"
    ]
    args.push( "--keyserver-options", "debug=1")  if env().get_debug()
    args.push( "--output", o ) if (o = @argv.output)?
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
    await @handle_track     esc defer() if @found_sig and @try_track()
    cb null

##=======================================================================

