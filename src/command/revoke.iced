{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
session = require '../session'
{make_esc} = require 'iced-error'
{prompt_yn} = require '../prompter'
log = require '../log'
{key_select} = require '../keyselector'
{KeybasePushProofGen} = require '../sigs'
req = require '../req'
{E} = require '../err'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS:
    f :
      alias : "force"
      action : "storeTrue"
      help : "don't ask interactively, just do it!"


  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : []
      help : "revoke the currently active PGP keys"
    name = "revoke"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "search" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  get_the_go_ahead : (cb) ->
    err = null
    unless @argv.force
      opts = 
        prompt : "DANGER ZONE! Really revoke your key and cancel all signatures"
        defval  : false
      await prompt_yn opts, defer err, ans
      err = new E.CancelError "No go-ahead given" unless ans
    cb err

  #----------

  revoke_key : (cb) ->
    args = 
      revoke_primary  : 1
      revocation_type : 0
    await req.post { endpoint : "key/revoke", args }, defer err
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "run"
    await session.login esc defer()
    await @get_the_go_ahead esc defer()
    await @revoke_key esc defer()
    log.info "success!"
    cb null

##=======================================================================

