{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferOutStream,BufferInStream} = require('gpg-wrapper')
{chain,make_esc} = require 'iced-error'
{env} = require '../env'
{TmpPrimaryKeyRing} = require '../keyring'
{TrackSubSubCommand} = require '../tracksubsub'
{TrackWrapper} = require '../trackwrapper'
{athrow} = require('pgp-utils').util
{parse_signature} = require '../gpg'
colors = require 'colors'
{constants} = require '../constants'
{User} = require '../user'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  @OPTS :
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

  #----------

  try_track : () -> @argv.track or @argv.track_remote or @argv.track_local

  #----------

  find_signature : (cb) ->
    [err, @signing_key] = parse_signature @decrypt_stderr.data().toString('utf8')
    @found_sig = not err?
    if (err instanceof E.NotFoundError) and not @argv.signed and not @argv.signed_by?
      log.debug "| No signatured found; but we didn't require one"
      err = null
    cb err

  #----------

  handle_track : (cb) ->
    await @tssc.all_prompts defer err, accept
    await @tssc.key_cleanup { accept } , defer e2
    if e2?
      log.warn "Error in key cleanup: #{e2.message}"
    cb err

  #----------

  handle_signature : (cb) ->
    esc = make_esc cb, "handle_signature"
    await @check_imports esc defer()
    arg = 
      type : constants.lookups.key_fingerprint_to_user
      name : @signing_key.primary
    await User.map_key_to_user arg, esc defer basics

    opts =
      local : @argv.track_local
      remote : @argv.track_remote

    @username = basics.username
    if (a = @argv.signed_by)? and (a isnt (b = @username))
      err = new E.WrongSignerError "Wrong signer: wanted '#{a}' but got '#{b}'"
      await athrow err, esc defer()

    @tssc = new TrackSubSubCommand { args : { them : @username }, opts, @tmp_keyring  }
    await @tssc.on_decrypt esc defer()

    {remote,local} = @tssc.trackw.is_tracking()
    tracks = if remote then "tracking remotely & locally"
    else if local then "tracking locally only"
    else "not tracking"
    log.info "Valid signature from keybase user #{colors.bold(basics.username)} (#{tracks})"
    cb null

  #----------

  check_imports : (cb) ->
    esc = make_esc cb, "Command::check_imports"
    await @tmp_keyring.list_keys esc defer ids
    err = null
    if ids.length is 0
      log.debug "| No new keys imported"
    else if ids.length > 1
      err = new E.CorruptionError "Too many imported keys: #{ids.length}"
    else
      ki64 = ids[0]
      log.debug "| Found new key in the keyring: #{ki64}"
      if ki64 isnt (b = @signing_key.primary[-(ki64.length)...])
        err = new E.VerifyError "Bad imported key; wanted #{b} but got #{ki64}"
    cb err

  #----------

  do_output : (o) ->

  #----------

  do_command : (cb) ->
    gargs = @make_gpg_args()
    @decrypt_stderr = gargs.stderr
    await @tmp_keyring.gpg gargs, defer err, out
    @do_output out
    cb err 

  #----------

  setup_tmp_keyring : (cb) ->
    await TmpPrimaryKeyRing.make defer err, @tmp_keyring
    cb err

  #----------

  cleanup : (cb) ->
    if env().get_preserve_tmp_keyring()
      log.info "Preserving #{@tmp_keyring.to_string()}"
    else
      await @tmp_keyring.nuke defer e2
      if e2?
        log.warn "Error cleaning up temporary keyring: #{e2.message}"
    cb()

  #----------

  rm_homedir : (cb) ->

  #----------

  run : (cb) ->
    cb = chain cb, @cleanup.bind(@)
    esc = make_esc cb, "Command::run"
    await @setup_tmp_keyring esc defer()
    await @do_command esc defer()
    await @find_signature esc defer()
    if @found_sig
      await @handle_signature esc defer()
      if @try_track()
        await @handle_track esc defer()
    cb null

##=======================================================================

