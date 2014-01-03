
{db} = require './db'
{constants} = require './constants'
log = require './log'
proofs = require 'keybase-proofs'
{proof_type_to_string} = proofs
ST = constants.signature_types
deq = require 'deep-equal'
{E} = require './err'
{unix_time} = require('pgp-utils').util
{make_esc} = require 'iced-error'
{prompt_yn} = require './prompter'
colors = require 'colors'
{session} = require './session'
{User} = require './user'
db = require './db'
util = require 'util'
{env} = require './env'
{TrackWrapper} = require './trackwrapper'

##=======================================================================

exports.TrackSubSubCommand = class TrackSubSubCommand

  #----------------------

  constructor : ({@args, @opts}) ->

  #----------------------

  prompt_ok : (warnings, cb) ->
    prompt = if warnings
      log.console.log colors.red "Some remote proofs failed!"
      "Still verify this user?"
    else
      "Are you satisfied with these proofs?"
    await prompt_yn { prompt, defval : false }, defer err, ret
    cb err, ret

  #----------

  prompt_track : (cb) ->
    ret = err = null
    if @opts.remote then ret = true
    else if (@opts.batch or @opts.local) then ret = false
    else
      prompt = "Permnanently track this user, and write proof to server?"
      await prompt_yn { prompt, defval : true }, defer err, ret
    cb err, ret

  #----------

  run : (cb) ->
    esc = make_esc cb, "Verify::run"
    log.debug "+ run"

    await User.load_me esc defer me

    await User.load { username : @args.them }, esc defer them
    await them.import_public_key esc defer found

    # After this point, we have to recover any errors and throw away 
    # our key if necessary. So call into a subfunction.
    await @_run2 {me, them}, defer err, accept

    if accept 
      log.debug "| commit_key"
      await them.commit_key esc defer()
    else if not found
      log.debug "| remove_key"
      await them.remove_key esc defer()
    else 
      log.debug "| leave key as is; neither accepted nor newly imported"

    log.debug "- run"
    cb err

  #----------

  _run2 : ({me, them}, cb) ->
    esc = make_esc cb, "Verify::_run2"
    log.debug "+ _run2"

    await them.verify esc defer()
    await TrackWrapper.load { tracker : me, trackee : them }, esc defer trackw
    
    check = trackw.skip_remote_check()
    if (check is constants.skip.NONE)
      log.console.log "...checking identity proofs"
      skp = false
    else 
      log.info "...all remote checks are up-to-date"
      skp = true
    await them.check_remote_proofs skp, esc defer warnings
    n_warnings = warnings.warnings().length

    if @opts.id
      log.debug "| We are just ID'ing this user, no reason to prompt"
      accept = false
    else if ((approve = trackw.skip_approval()) isnt constants.skip.NONE)
      log.debug "| skipping approval, since remote services & key are unchanged"
      accept = true
    else if @opts.batch
      log.debug "| We needed approval, but we were in batch mode"
      accept = false
    else
      await @prompt_ok n_warnings, esc defer accept

    err = null
    if @opts.id
      log.debug "| Skipping store operation, since we're in ID mode"
    else if not accept
      log.warn "Bailing out; proofs were not accepted"
      err = new E.CancelError "operation was canceled"
    else if (check is constants.skip.REMOTE) and (approve is constants.skip.REMOTE)
      log.info "Nothing to do; tracking is up-to-date"
    else
      await @prompt_track esc defer do_remote
      await session.load_and_login esc defer() if do_remote
      await trackw.store_track { do_remote }, esc defer()

    log.debug "- _run2"
    cb err, accept 

##=======================================================================
