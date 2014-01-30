
{db} = require './db'
{constants} = require './constants'
log = require './log'
proofs = require 'keybase-proofs'
{proof_type_to_string} = proofs
ST = constants.signature_types
deq = require 'deep-equal'
{GE,E} = require './err'
{athrow,unix_time} = require('pgp-utils').util
{chain_err,make_esc} = require 'iced-error'
{prompt_yn} = require './prompter'
colors = require 'colors'
{session} = require './session'
{User} = require './user'
db = require './db'
util = require 'util'
{env} = require './env'
{TrackWrapper} = require './trackwrapper'
{TmpKeyRing} = require './keyring'
assertions = require './assertions'

##=======================================================================

exports.TrackSubSubCommand = class TrackSubSubCommand

  @OPTS :
    r :
      alias : "track-remote"
      action : "storeTrue"
      help : "remotely track by default"
    l : 
      alias : "track-local"
      action : "storeTrue"
      help : "don't prompt for remote tracking"
    a :
      action : 'append'
      alias : "assert"
      help : "provide a key assertion"
    batch : 
      action : 'storeTrue'
      help : "batch-mode without interactivity"

  #----------------------

  constructor : ({@args, @opts, @tmp_keyring, @batch}) ->

  #----------------------

  is_batch : () -> @opts.batch or @batch

  #----------------------

  prompt_ok : (warnings, cb) ->
    prompt = if warnings
      log.console.error colors.red "Some remote proofs failed!"
      "Still verify this user?"
    else
      "Are you satisfied with these proofs?"
    await prompt_yn { prompt, defval : false }, defer err, ret
    cb err, ret

  #----------

  prompt_track : (cb) ->
    ret = err = null
    if @opts.track_remote then ret = true
    else if (@is_batch() or @opts.track_local) then ret = false
    else
      prompt = "Permanently track this user, and write proof to server?"
      await prompt_yn { prompt, defval : true }, defer err, ret
    cb err, ret

  #----------

  key_cleanup : ({accept}, cb) ->
    err = null
    if @them
      if accept 
        log.debug "| commit_key"
        await @them.key.commit @me?.key, defer err
      else
        await @them.key.rollback defer err
      
    if not @tmp_keyring then #noop
    else if env().get_preserve_tmp_keyring()
      log.info "Preserving #{@tmp_keyring.to_string()}"
    else
      await @tmp_keyring.nuke defer e2
      log.warn "Problem in cleanup: #{e2.message}" if e2?
    cb err

  #----------

  on_decrypt : (cb) ->
    esc = make_esc cb, "TrackSubSub::on_decrypt" 
    await User.load { username : @args.them }, esc defer @them
    @them.reference_public_key { keyring : @tmp_keyring }
    await User.load_me esc defer @me
    await @them.verify esc defer()
    await TrackWrapper.load { tracker : @me, trackee : @them }, esc defer @trackw
    cb null

  #----------

  check_remote_proofs : (skip, cb) ->
    esc = make_esc cb, "TrackSubSub::check_remote_proofs"
    await @parse_assertions esc defer()
    opts = { skip, @assertions } 
    await @them.check_remote_proofs opts, esc defer warnings
    if not err? and @assertions? and not(@assertions.check())
      err = new E.BadAssertionError()
    cb err, warnings

  #----------

  id : (cb) ->
    cb = chain_err cb, @key_cleanup.bind(@, {})
    esc = make_esc cb, "TrackSubSub:id"
    log.debug "+ id"
    accept = false
    await User.load { username : @args.them }, esc defer @them
    await TmpKeyRing.make esc defer @tmp_keyring
    await @them.import_public_key { keyring : @tmp_keyring }, esc defer()
    await @them.verify esc defer()
    await @check_remote_proofs false, esc defer warnings # err isn't a failure here
    log.debug "- id"
    cb null

  #----------

  parse_assertions : (cb) ->
    err = null
    [err, @assertions] = assertions.parse(a) if (a = @opts.assert)?
    cb err

  #----------

  run : (cb) ->
    opts = {}
    cb = chain_err cb, @key_cleanup.bind(@, opts)

    esc = make_esc cb, "TrackSubSub::run"
    log.debug "+ run"

    await User.load_me esc defer @me
    await User.load { username : @args.them, ki64 : @args.them_ki64 }, esc defer @them

    # First see if we already have the key, in which case we don't
    # need to reimport it.
    await @them.check_public_key esc defer found_them
    if found_them
      await @them.load_public_key { signer : @me.key }, esc defer()
    else if not (@tmp_keyring = @args.tmp_keyring)?
      await @me.new_tmp_keyring { secret : true }, esc defer @tmp_keyring

    # After this point, we have to recover any errors and throw away 
    # our key if necessary

    unless found_them
      await @them.import_public_key { keyring: @tmp_keyring }, esc defer()
    await @them.verify esc defer()
    await TrackWrapper.load { tracker : @me, trackee : @them }, esc defer @trackw
    await @all_prompts esc defer opts.accept

    log.debug "- run"

    cb null

  #----------

  all_prompts : (cb) ->
    esc = make_esc cb, "TrackSubSub::all_prompts"
    log.debug "+ TrackSubSub::all_prompts"
    
    check = @trackw.skip_remote_check()
    if (check is constants.skip.NONE)
      log.console.error "...checking identity proofs"
      skp = false
    else 
      log.info "...all remote checks are up-to-date"
      skp = true
    await @check_remote_proofs skp, esc defer warnings
    n_warnings = warnings.warnings().length

    if ((approve = @trackw.skip_approval()) isnt constants.skip.NONE)
      log.debug "| skipping approval, since remote services & key are unchanged"
      accept = true
    else if @is_batch()
      log.debug "| We needed approval, but we were in batch mode"
      accept = false
    else if @assertions?.clean()
      log.debug "| We can approve due to clean assertions"
      accept = true
    else
      await @prompt_ok n_warnings, esc defer accept

    err = null
    if not accept
      log.warn "Bailing out; proofs were not accepted"
      err = new E.CancelError "operation was canceled"
    else if (check is constants.skip.REMOTE) and (approve is constants.skip.REMOTE)
      log.info "Nothing to do; tracking is up-to-date"
    else
      await @prompt_track esc defer do_remote
      await session.load_and_login esc defer() if do_remote
      await @trackw.store_track { do_remote }, esc defer()

    log.debug "- TrackSubSub::all_prompts"
    cb err, accept 

##=======================================================================
