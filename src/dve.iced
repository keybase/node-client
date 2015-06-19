log = require './log'
{E} = require './err'
{TrackSubSubCommand} = require './tracksubsub'
{BufferOutStream,BufferInStream} = require('iced-spawn')
{chain,make_esc} = require 'iced-error'
{env} = require './env'
{TmpPrimaryKeyRing} = require './keyring'
{athrow} = require('pgp-utils').util
{parse_signature} = require './gpg'
{constants} = require './constants'
{User} = require './user'
{dict_union} = require './util'
timeago = require 'timeago'
urlmod = require 'url'
{HKPLoopback} = require './hkp_loopback'
{fingerprint_to_key_id_64} = require('pgp-utils').util
colors = require './colors'
session = require './session'

# Decrypt And Verify Engine

##=======================================================================

exports.DecryptAndVerifyEngine = class DecryptAndVerifyEngine

  #----------


  @OPTS : dict_union TrackSubSubCommand.OPTS, {
    t :
      alias : "track"
      action : "storeTrue"
      help : "prompt for tracking if necessary"
    I:
      alias: 'no-id'
      action : 'storeTrue'
      help : "don't try to ID the user"
  }

  #----------

  constructor : ({@argv}) ->

  #----------

  try_track : () ->
    (@argv.track or @argv.track_remote or @argv.track_local) and not @is_self

  #----------

  try_id : () -> (not @is_self and not @argv.no_id)

  #----------

  find_signature : (cb) ->
    log.debug "+ find_signature"
    [err, @signing_key, @sig_date] = parse_signature @decrypt_stderr.data()
    @found_sig = not err?
    if (err instanceof E.NotFoundError) and not @argv.signed and not @argv.signed_by?
      log.debug "| No signature found; but we didn't require one"
      err = null
    log.debug "- find_signature"
    cb err

  #----------

  handle_id : (cb) ->
    log.debug "+ handle_id"
    await @tssc.check_remote_proofs false, defer err, warnings
    log.debug "- handle_id"
    cb err

  #----------

  handle_track : (cb) ->
    esc = make_esc cb, "handle_track"
    log.debug "+ handle track"
    await @tssc.all_prompts esc defer accept
    await @tssc.save_their_keys esc defer() if accept
    log.debug "- handle track"
    cb null

  #----------

  handle_signature : (cb) ->
    esc = make_esc cb, "handle_signature"
    log.debug "+ handle_signature"
    await @check_imports esc defer()
    arg =
      type : constants.lookups.key_fingerprint_to_user
      name : @signing_key.primary
    await User.map_key_to_user arg, esc defer basics

    @username = basics.username
    if (a = @argv.signed_by)? and (a isnt (b = @username))
      err = new E.WrongSignerError "Wrong signer: wanted '#{a}' but got '#{b}'"
      await athrow err, esc defer()

    if env().is_me @username
      @is_self = true
      log.info "Valid signature from #{colors.bold('you')}"
    else
      @is_self = false
      @tssc = new TrackSubSubCommand {
        args : { them : @username },
        opts : @argv,
        @tmp_keyring,
        @batch,
        ran_keypull : @_ran_keypull
      }

      if session.logged_in()
        await @tssc.on_decrypt esc defer()

        {remote,local} = @tssc.trackw.is_tracking()
        tracks = if remote then "tracking remotely & locally"
        else if local then "tracking locally only"
        else "not tracking"
      else
        await @tssc.on_loggedout_verify esc defer()
        tracks = "not tracking"

      log.info "Valid signature from keybase user #{colors.bold(basics.username)} (#{tracks})"

    d = @sig_date
    time_ago = timeago d
    date_signed = d.toLocaleString()
    log.info "Signed #{time_ago} (#{date_signed})"

    log.debug "- handle_signature"
    cb null

  #----------

  check_imports : (cb) ->
    esc = make_esc cb, "Command::check_imports"
    await @tmp_keyring.list_keys esc defer ids
    err = null
    if ids.length is 0
      log.debug "| No new keys imported"
    else if ids.length > 1 and not env().get_no_gpg_options()
      # In the case in which we're ignoring the GPG configuration file
      # (because it interferes with our command-line switches), then
      # we are safe to ignore this exception.
      err = new E.CorruptionError "Too many imported keys: #{ids.length}"
    else
      b = fingerprint_to_key_id_64 @signing_key.primary
      if not (b in ids)
        err = new E.VerifyError "Bad imported key; wanted #{b} but couldn't find it"
      else
        log.debug "| Found new key in the keyring: #{b}"
    cb err

  #----------

  do_output : (o, cb) -> cb()

  #----------

  do_keypull : (cb) ->
    @_ran_keypull = false
    cb null

  #----------

  make_gpg_args : () ->
    args = [
      "--status-fd", '2',
      "--with-colons",
      "--keyid-format", "long",
      "--keyserver" , @hkpl.url()
      "--keyserver-options", "auto-key-retrieve=1", # needed for GPG 1.4.x
      "--with-fingerprint"
    ]
    args.push( "--keyserver-options", "debug=1")  if env().get_debug()
    args.push( "--output", o ) if (o = @argv.output)?

    @patch_gpg_args args

    gargs = { args }
    gargs.stderr = new BufferOutStream()
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message
    else if not @get_files(args)
      gargs.stdin = process.stdin
      @batch = true

    return gargs

  #----------

  make_hkp_loopback : (cb) ->
    @hkpl = new HKPLoopback()
    await @hkpl.listen defer err
    @hkpl = null if err?
    cb null

  #----------

  do_command : (cb) ->
    esc = make_esc cb, "Command::do_command"
    gargs = @make_gpg_args()
    @decrypt_stderr = gargs.stderr
    await @tmp_keyring.gpg gargs, defer err, out
    await @do_output out, defer()
    if err?
      log.warn @decrypt_stderr.data().toString('utf8')
    else if env().get_debug()
      log.debug @decrypt_stderr.data().toString('utf8')

    cb err

  #----------

  setup_tmp_keyring : (cb) ->
    await TmpPrimaryKeyRing.make defer err, @tmp_keyring
    cb err

  #----------

  run_cleanup : (cb) ->
    if env().get_preserve_tmp_keyring()
      log.info "Preserving #{@tmp_keyring.to_string()}"
    else if @tmp_keyring?
      await @tmp_keyring.nuke defer e2
      if e2?
        log.warn "Error cleaning up temporary keyring: #{e2.message}"
    cb()

  #----------

  global_cleanup : (cb) ->
    if @hkpl
      await @hkpl.close defer err
      if err?
        log.warning "Error closing HKP loopback server: #{err}"
    cb err

  #----------

  global_init : (cb) ->
    await @make_hkp_loopback defer err
    cb err

  #----------

  run : (cb) ->

    cb = chain cb, @run_cleanup.bind(@)
    esc = make_esc cb, "DecryptAndVerifyEngine::run"

    # Do this first and store our secret key if we need it
    await @do_keypull esc defer()

    await @setup_tmp_keyring esc defer()
    await @do_command esc defer()
    await @find_signature esc defer()
    if @found_sig
      await @handle_signature esc defer()
      if @try_track()
        await @handle_track esc defer()
      else if @try_id()
        await @handle_id esc defer()
    cb null

##=======================================================================

