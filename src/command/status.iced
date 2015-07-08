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

  OPTS : 
    T :
      alias : 'text'
      action : 'storeTrue'
      help : 'output in text format; default is JSON'

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "print current status"
    name = "status"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ]

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"

    if (un = env().get_username())?
      await session.check esc defer logged_in
      await User.load_me {secret : false}, esc defer me

      obj = 
        status :
          configured : true
          logged_in : logged_in
        user : 
          name : un
      if me?
        obj.user.key = 
          key_id : me.key_id_64()?.toUpperCase()
          fingerprint : if me.fingerprint()? then format_fingerprint me.fingerprint(true)
        if (rp = me.list_remote_proofs())?
          obj.user.proofs = rp
        if (d = me.list_cryptocurrency_addresses())?
          obj.user.cryptocurrency = d
    else
      obj = { status : { configured : false } }

    @output obj
    cb null

  #-----------------

  output_text : (obj) ->
    if obj.status.configured
      log.console.log "configged as #{obj.user.name}"
      log.console.log "  * #{if obj.status.logged_in then '' else 'NOT '}logged in"
      if (ko = obj.user.key)?
        log.console.log "  * Key ID: #{ko.key_id}"
        log.console.log "  * Fingerprint: #{ko.fingerprint}"
      if (rp = obj.user.proofs)?
        log.console.log "Remote proofs:"
        for k,v of rp
          log.console.log "  * #{k}: #{v}"
      if (ct = obj.user.cryptocurrency)?
        log.console.log "Cryptocurrency Addresses:"
        for k,v of ct
          log.console.log "  * #{k}: #{v}"

    else
      log.error "Not configured"

  #-----------------

  output : (obj) ->
    if @argv.text
      @output_text obj
    else
      log.console.log JSON.stringify(obj, null, "  ")

##=======================================================================

