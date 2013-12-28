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
{Track} = require '../track'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    t :
      alias : "track"
      help : "remotely track by default"
    n : 
      alias : "no-track"
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
      await prompt_yn { prompt, defval : true }, defer err, track
    cb err, track


  #----------

  run : (cb) ->
    esc = make_esc cb, "Verify::run"

    await db.open esc defer()
    await User.load { username : env().get_username() }, esc defer me
    await me.check_public_key esc defer()
    await me.verify esc defer()

    await User.load { username : @argv.them[0] }, esc defer them
    await them.import_public_key esc defer found

    # After this point, we have to recover any errors and throw away 
    # our key is necessary. So call into a subfunction.
    await @_run2 {me, them}, defer err, accept

    if accept 
      await them.commit_key esc defer()
    else if not found
      await them.remove_key esc defer()

    cb err

  #----------

  track : ( { user, do_remote }, cb) ->
    log.debug "+ track user (remote=#{do_remote})"
    obj = user.gen_track_obj()
    log.debug "| object generated: #{JSON.stringify(obj)}"
    log.debug "- tracked user"
    cb null

  #----------

  _run2 : ({me, them}, cb) ->
    esc = make_esc cb, "Verify::_run2"

    await them.verify esc defer()
    await Track.load { tracker : me, trackee : them }, esc defer track
    
    if not track.skip_remote_check()
      log.console.log "...checking identity proofs"
      await them.check_remote_proofs esc defer warnings
    else
      log.info "...skipping remote checks"

    if track.skip_approval()
      log.debug "| skpping approval, since remote services & key are unchanged"
      accept = true
    else if @argv.batch
      log.debug "| We needed approval, but we were in batch mode"
      accept = false
    else
      await @prompt_ok warnings.warnings().length, esc defer accept

    err = null
    if not accept
      log.warn "Bailing out; proofs were not accepted"
      err = new E.CancelError "operation was canceled"
    else
      await @prompt_track esc defer do_remote
      await @track { user : them, do_remote }, esc defer()

    cb err, accept

##=======================================================================

