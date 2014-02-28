
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
{keypull} = require './keypull'

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
    "prompt-remote" :
      action : 'storeTrue'
      help : "prompt for remote tracking"

  #----------------------

  constructor : ({@args, @opts, @tmp_keyring, @batch, @track_local, @ran_keypull}) ->
    @opts or= {}

  #----------------------

  is_batch : () -> @opts.batch or @batch

  #----------------------

  prompt_ok : (warnings, proofs, cb) ->
    them = @args.them
    prompt = if warnings
      log.console.error colors.red "Some remote proofs failed!"
      "Still verify this user as #{them}?"
    else if proofs is 0
      "We found an account for #{them}, but they haven't proved their identity. Still accept them?"
    else
      "Is this the #{them} you wanted?"
    await prompt_yn { prompt, defval : false }, defer err, ret
    cb err, ret

  #----------

  prompt_track : (proofs, cb) ->
    ret = err = null
    if @opts.track_remote then ret = true
    else if (@is_batch() or @opts.track_local or @track_local) and not @opts.prompt_remote 
      ret = false
    else
      prompt = "Permanently track this user, and write proof to server?"
      await prompt_yn { prompt, defval : true }, defer err, ret
    cb err, ret

  #----------

  key_cleanup : ({accept}, cb) ->
    log.debug "+ key_cleanup"
    err = null
    if @them
      if accept 
        log.debug "| commit_key"
        await @them.key.commit {}, defer err
      else if @them.key?
        await @them.key.rollback defer err
      
    if not @tmp_keyring then #noop
    else if env().get_preserve_tmp_keyring()
      log.info "Preserving #{@tmp_keyring.to_string()}"
    else
      await @tmp_keyring.nuke defer e2
      log.warn "Problem in cleanup: #{e2.message}" if e2?
    log.debug "- key_cleanup"
    cb err

  #----------

  on_decrypt : (cb) ->
    esc = make_esc cb, "TrackSubSub::on_decrypt" 
    await @keypull esc defer()
    await User.load { username : @args.them }, esc defer @them
    @them.reference_public_key { keyring : @tmp_keyring }
    await User.load_me {secret : true}, esc defer @me
    await @check_not_self esc defer()
    await @them.verify esc defer()
    await TrackWrapper.load { tracker : @me, trackee : @them }, esc defer @trackw
    cb null

  #----------

  check_remote_proofs : (skip, cb) ->
    esc = make_esc cb, "TrackSubSub::check_remote_proofs"
    log.debug "+ TrackSubSub::check_remote_proofs"
    await @parse_assertions esc defer()
    opts = { skip, @assertions } 
    await @them.check_remote_proofs opts, esc defer warnings, n_proofs
    if not err? and @assertions? and not(@assertions.check())
      err = new E.BadAssertionError()
    log.debug "- TrackSubSub::check_remote_proofs -> #{err?.message}"
    cb err, warnings, n_proofs

  #----------

  id : (cb) ->
    cb = chain_err cb, @key_cleanup.bind(@, {})
    esc = make_esc cb, "TrackSubSub:id"
    log.debug "+ id"
    accept = false
    await User.load { username : @args.them, require_public_key : true }, esc defer @them
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

  check_not_self : (cb) ->
    err = null
    if (((t = @args.them)? and (t is @me.username())) or
        ((t = @args.them_ki64)? and (t is @me.key_id_64())))
      err = new E.SelfError "Cannot track yourself"
    cb err

  #----------

  keypull : (cb) ->
    unless @ran_keypull
      await keypull { need_secret : true, stdin_blocked : @is_batch() }, defer err
      @ran_keypull = true
    cb err

  #----------

  run : (cb) ->
    opts = {}
    cb = chain_err cb, @key_cleanup.bind(@, opts)

    esc = make_esc cb, "TrackSubSub::run"
    log.debug "+ run"

    # We might need to fetch our key from the server...
    await @keypull esc defer()

    await User.load_me {secret : true}, esc defer @me
    await @check_not_self esc defer()
    await User.load { username : @args.them, ki64 : @args.them_ki64, require_public_key : true }, esc defer @them

    # First see if we already have the key, in which case we don't
    # need to reimport it.
    await @them.check_key {secret : false}, esc defer ckres
    if (found_them = ckres.local)
      await @them.load_public_key { signer : @me.key }, esc defer()
    else if not ckres.remote
      await athrow (new E.NoRemoteKeyError "#{@args.them} doesn't have a public key"), esc defer()
    else if not (@tmp_keyring = @args.tmp_keyring)?
      await TmpKeyRing.make esc defer @tmp_keyring

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
      log.info "...checking identity proofs"
      skp = false
    else 
      log.info "...all remote checks are up-to-date"
      skp = true
    await @check_remote_proofs skp, esc defer warnings, n_proofs
    n_warnings = warnings.warnings().length

    if ((approve = @trackw.skip_approval()) isnt constants.skip.NONE)
      log.debug "| skipping approval, since remote services & key are unchanged"
      accept = true
    else if @assertions?.clean()
      log.info "Identity accepted due to clean and complete assertions"
      log.debug "| We can approve due to clean assertions"
      accept = true
    else if @is_batch()
      log.warn "Interactive approval is needed"
      log.debug "| We needed approval, but we were in batch mode"
      accept = false
    else
      await @prompt_ok n_warnings, n_proofs, esc defer accept

    err = null
    if not accept
      log.warn "Bailing out; proofs were not accepted"
      err = new E.CancelError "operation was canceled"
    else if (check is constants.skip.REMOTE) and (approve is constants.skip.REMOTE)
      log.info "Nothing to do; tracking is up-to-date"
    else
      if (approve is constants.skip.REMOTE)
        do_remote = false
      else
        await @prompt_track n_proofs, esc defer do_remote
        if do_remote
          await session.load_and_login esc defer()
      await @trackw.store_track { do_remote }, esc defer()

    log.debug "- TrackSubSub::all_prompts"
    cb err, accept 

##=======================================================================
