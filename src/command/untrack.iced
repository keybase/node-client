{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
db = require '../db'
{User} = require '../user'
{session} = require '../session'
{TrackWrapper} = require '../trackwrapper'
{athrow} = require('pgp-utils').util
{prompt_yn} = require '../prompter'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    k :
      alias : 'remove-key'
      action : 'storeTrue'
      help : 'remove key from GPG keyring'
    b : 
      alias : 'batch'
      action : 'storeTrue'
      help : "run in batch mode / don't prompt"
    K:
      alias : "keep-key"
      action : 'storeTrue'
      help : "preserve key in GPG keyring"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "unverify" ]
      help : "untrack this user"
    name = "untrack"
    sub = scp.addParser name, opts
    sub.addArgument ["them"], { nargs : 1 , help : "the username of the user to untrack" }
    add_option_dict sub, @OPTS
    return opts.aliases.concat [ name ]

  #----------

  needs_configuration : () -> true
  
  #----------

  remove_key : (them, cb) ->
    esc = make_esc cb, "Untrack::remove_key"
    go = false
    if @argv.remove_key then go = true
    else if @argv.keep_key then go = false
    else if @argv.batch
      log.warn "Not removing key; in batch mode"
      go = false
    else
      args = 
        prompt : "Remove #{@their_name}'s public key from your local keyring? "
        defval : true 
      await prompt_yn args, esc defer go
    if go
      await them.remove_key esc defer()
    cb null

  #----------

  run : (cb) ->
    esc = make_esc cb, "Untrack::run"
    log.debug "+ run"

    await User.load_me {secret : true }, esc defer me

    # Resolve the username if it's in social-form
    await User.resolve_user_name { username : @argv.them[0] }, esc defer @their_name
    await User.load { username : @their_name }, esc defer them

    await TrackWrapper.load { tracker : me, trackee : them }, esc defer trackw
    {remote,local} = trackw.is_tracking()

    if not remote and not local
      err = new E.UntrackError "You're not tracking '#{them.username()}'"
      await athrow err, esc defer()
    else if remote
      untrack_obj = them.gen_untrack_obj()
      await me.gen_track_proof_gen { uid : them.id, untrack_obj }, esc defer g
      await session.load_and_login esc defer()
      await g.run esc defer()
    else
      log.warn "You're not remotely tracking '#{them.username()}'; purging local state"

    await @remove_key them, esc defer() 
    await TrackWrapper.remove_local_track {uid : them.id}, esc defer()

    log.debug "- run"
    cb err

##=======================================================================

