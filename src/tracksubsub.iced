
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
{session} = require './session'
{User} = require './user'
db = require './db'
util = require 'util'
{env} = require './env'
{TrackWrapper} = require './trackwrapper'
{master_ring} = require './keyring'
{assertion} = require 'libkeybase'
{keypull} = require './keypull'
colors = require './colors'
tor = require './tor'

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
      alias : "assert"
      help : "provide an identity assertion"
    batch :
      action : 'storeTrue'
      help : "batch-mode without interactivity"
    "prompt-remote" :
      action : 'storeTrue'
      help : "prompt for remote tracking"

  #----------------------

  constructor : ({@args, @opts, @tmp_keyring, @batch, @track_local, @ran_keypull, @assertions}) ->
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
    if @opts.track_remote
      ret = true
    else if @is_batch()
      ret = false
    else if not @me.have_secret_key()
      ret = false
    else if (@opts.track_local or @track_local) and not @opts.prompt_remote
      ret = false
     else
      prompt = "Permanently track this user, and write proof to server?"
      await prompt_yn { prompt, defval : true }, defer err, ret
    cb err, ret

  #----------

  on_loggedout_verify : (cb) ->
    esc = make_esc cb, "TrackSubSub::on_loggedout_verify"
    await User.load { username : @args.them }, esc defer @them
    cb null

  #----------

  on_decrypt : (cb) ->
    esc = make_esc cb, "TrackSubSub::on_decrypt"
    await @keypull esc defer()
    await User.load { username : @args.them }, esc defer @them
    await User.load_me {maybe_secret : true}, esc defer @me
    await @check_not_self esc defer()
    await TrackWrapper.load { tracker : @me, trackee : @them }, esc defer @trackw
    cb null

  #----------

  check_remote_proofs : (skip, cb) ->
    esc = make_esc cb, "TrackSubSub::check_remote_proofs"
    log.debug "+ TrackSubSub::check_remote_proofs"
    await @parse_assertions esc defer()
    opts = { skip, @assertions }
    await @them.check_remote_proofs opts, esc defer warnings, n_proofs
    err = null
    log.debug "- TrackSubSub::check_remote_proofs -> #{err?.message}"
    cb err, warnings, n_proofs

  #----------

  resolve_them : (cb) ->
    await User.resolve_user_name { username : @args.them }, defer err, @args.them, @assertion
    cb err

  #----------

  id : (cb) ->
    esc = make_esc cb, "TrackSubSub:id"
    log.debug "+ id"
    accept = false
    await @resolve_them esc defer()
    await User.load { username : @args.them, require_public_key : true }, esc defer @them
    await @check_remote_proofs false, esc defer warnings # err isn't a failure here
    await @them.display_cryptocurrency_addresses {}, esc defer()
    log.debug "- id"
    cb null

  #----------

  pre_encrypt : (cb) ->
    if not env().is_configured()
      await @id defer err
    else
      await session.load_and_check defer err, logged_in
      unless err?
        @skip_keypull = not(logged_in)
        @track_local = not(logged_in)
        await @run defer err
    cb err

  #----------

  parse_assertions : (cb) ->
    err = null
    ca = null
    try
      ca = assertion.parse(a) if (a = @opts.assert)?
    catch e
      err = new E.ParseAssertionError "Error parsing assertion '#{a}': #{e.message}"

    # If we get assertions back, and we already have assertions from
    # username lookups, we have to satisfy all of them, so AND them together
    if @assertions? and ca?
      @assertions = new assertion.AND @assertions, ca
    else if ca?
      @assertions = ca

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
    err = null
    if not(@ran_keypull) and not(@skip_keypull) and not tor.enabled()
      await keypull { need_secret : false, stdin_blocked : @is_batch() }, defer err
      @ran_keypull = true
    cb err

  #----------

  save_their_keys : (cb) ->
    esc = make_esc cb, "TrackSubSub::save_their_keys"
    for key in @them.gpg_keys
      await key.copy_to_keyring(master_ring()).save esc defer()
    cb null

  #----------

  run : (cb) ->

    esc = make_esc cb, "TrackSubSub::run"
    log.debug "+ run"

    # We might need to fetch our key from the server...
    await @keypull esc defer()

    await User.load_me {maybe_secret : true}, esc defer @me
    await @check_not_self esc defer()

    await @resolve_them esc defer()
    await User.load { username : @args.them, ki64 : @args.them_ki64, require_public_key : true }, esc defer @them

    await TrackWrapper.load { tracker : @me, trackee : @them }, esc defer @trackw
    await @all_prompts esc defer accept

    # First see if we already have the key, in which case we don't
    # need to reimport it.
    await @them.check_key {secret : false, store : true }, esc defer ckres
    if accept and not ckres.local
      await @save_their_keys esc defer()

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
    else if @assertions?
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
      else if tor.strict()
        log.warn "Can't write tracking statement to server in strict Tor mode"
      else
        await @prompt_track n_proofs, esc defer do_remote
        if do_remote
          await session.load_and_login esc defer()
      await @trackw.store_track { do_remote }, esc defer()

    log.debug "- TrackSubSub::all_prompts"
    cb err, accept

##=======================================================================
