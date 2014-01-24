{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{session} = require '../session'
{make_esc} = require 'iced-error'
{env} = require '../env'
log = require '../log'
{User} = require '../user'
{format_fingerprint} = require('pgp-utils').util

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "print current status"
    name = "status"
    sub = scp.addParser name, opts
    return [ name ]

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    log.console.log "configged as #{env().get_username()}"
    await session.check esc defer logged_in
    log.console.log "  * #{if logged_in then '' else 'NOT '}logged in"
    await User.load_me esc defer me
    if me?
      log.console.log "  * Key ID: #{me.key_id_64().toUpperCase()}"
      log.console.log "  * Fingerprint: #{format_fingerprint me.fingerprint(true)}"
    cb null

##=======================================================================

