{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_remote_username} = require '../prompter'
{TwitterProofGen,GithubProofGen} = require '../sigs'
{User} = require '../user'

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
    sub.addArgument [ "remote_username"], { nargs : "?", help : "username at that service" }
    return opts.aliases.concat [ name ]

  #----------

  prompt_remote_username : (cb) ->
    svc = @argv.service[0]
    err = null
    unless (ret = @argv.remote_username)?
      await prompt_remote_username svc, defer err, ret
    @remote_username = ret
    cb err, ret

  #----------

  allocate_proof_gen : (cb) ->
    table =
      twitter : TwitterProofGen
      twtr : TwitterProofGen
      git : GithubProofGen
      github : GithubProofGen
      gith : GithubProofGen
    klass = table[@argv.service[0].toLowerCase()]
    if klass?
      await @me.gen_remote_proof_gen { klass, @remote_username }, defer err, @gen
    else
      err = new E.UnknownServiceError "Unknown service: #{@argv.service[0]}"
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    console.log "A"
    await @prompt_remote_username esc defer()
    console.log "B"
    await User.load_me esc defer @me
    console.log "C"
    await @allocate_proof_gen esc defer()
    console.log "D"
    await @gen.run esc defer()
    console.log "E"
    console.log @gen
    cb null

##=======================================================================

