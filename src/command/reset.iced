{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
session = require '../session'
{make_esc} = require 'iced-error'
{prompt_yn} = require '../prompter'
log = require '../log'
{E} = require '../err'
{reset} = require '../setup'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    f : 
      alias : 'force'
      action : 'storeTrue'
      help : "don't prompt for approval; force it"

  #----------

  use_session : () -> true
  use_gpg : () -> false

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : [ 'nuke' ]
      help : "reset the local setup, deleting all local cached state"
    name = "reset"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return opts.aliases.concat [ name ]

  #----------

  prompt_yn : (cb) ->
    err = null
    unless @argv.force 
      args = 
        prompt : "DANGER! Log yourself out, deregister this client, and remove local cache?"
        defval : false
      await prompt_yn args, defer err, ret
      err = new E.CancelError "no go-ahead given" unless ret
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @prompt_yn esc defer()
    await reset {}, esc defer()
    log.info "success!"
    cb null

##=======================================================================

