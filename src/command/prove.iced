{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_remote_username} = require '../prompter'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "proof" ]
      help : "add a proof of identity"
    name = "prove"
    sub = scp.addParser name, opts
    sub.addArgument [ "service" ], { nargs : 1, help: "the name of service" }
    sub.addArgument [ "username"], { nargs : "?", help : "username at that service" }
    return opts.aliases.concat [ name ]

  #----------

  prompt_remote_username : (cb) ->
    svc = @argv.service[0]
    err = null
    unless (ret = @argv.username)?
      await prompt_remote_username svc, defer err, ret
    cb err, ret


  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @prompt_remote_username esc defer r_username
    cb new E.UnimplementedError "feature not implemented"

##=======================================================================

