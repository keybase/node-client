{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{make_esc} = require 'iced-error'
{User} = require '../user'
db = require '../db'
util = require 'util'
{env} = require '../env'
{prompt_yn} = require '../prompter'
colors = require 'colors'
{TrackWrapper} = require '../track'
proofs = require 'keybase-proofs'
{session} = require '../session'
{constants} = require '../constants'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    t :
      alias : "track"
      action : "storeTrue"
      help : "remotely track by default"
    n : 
      alias : "no-track"
      action : "storeTrue"
      help : "never track"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "vrfy" ]
      help : "verify a user's authenticity"
    name = "verify"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "them" ], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #----------

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
    if @argv.track then ret = true
    else if (@argv.batch or @argv.no_track) then ret = false
    else
      prompt = "Permnanently track this user, and write proof to server?"
      await prompt_yn { prompt, defval : true }, defer err, ret
    cb err, ret

  #----------

  run : (cb) ->
    esc = make_esc cb, "Verify::run"
    log.debug "+ run"

    await db.open esc defer()
    await User.load_me esc defer me

    await User.load { username : @argv.them[0] }, esc defer them
    await them.import_public_key esc defer found

    # After this point, we have to recover any errors and throw away 
    # our key is necessary. So call into a subfunction.
    await @_run2 {me, them}, defer err, accept

    if accept 
      log.debug "| commit_key"
      await them.commit_key esc defer()
    else if not found
      log.debug "| remove_key"
      await them.remove_key esc defer()

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

    if ((approve = trackw.skip_approval()) isnt constants.skip.NONE)
      log.debug "| skipping approval, since remote services & key are unchanged"
      accept = true
    else if @argv.batch
      log.debug "| We needed approval, but we were in batch mode"
      accept = false
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
      await trackw.store_track { do_remote }, esc defer()

    log.debug "- _run2"
    cb err, accept

##=======================================================================

