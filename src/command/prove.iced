{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_yn,prompt_remote_username} = require '../prompter'
{TwitterProofGen,GithubProofGen} = require '../sigs'
{User} = require '../user'
{req} = require '../req'

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

  poll_server : (cb) ->
    arg = 
      endpoint : "sig/posted"
      args :
        proof_id : @gen.proof_id
    await req arg, defer err, body
    res = if err? then false else body.proof_ok
    cb err, res

  #----------

  handle_post : (cb) ->
    log.console.log "Please #{@gen.imperative_verb()} the following:"
    log.console.log ""
    log.console.log @gen.proof_text
    log.console.log ""
    prompt = true
    esc = make_esc cb, "Command::prompt"
    found = false
    first = true

    while prompt
      await prompt_yn { prompt : "Check #{@gen.display_name()} #{if first then '' else 'again '}now?", defval : true }, esc defer prompt
      first = false
      if prompt
        await @poll_server esc defer found
        prompt = not found
        if not found
          log.warn "Didn't find the posted proof."
    err = if found then null else E.ProofNotAvailableError "Proof wasn't available; we'll keeping trying"
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @prompt_remote_username esc defer()
    await User.load_me esc defer @me
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    await @handle_post esc defer()
    log.info "Success!"
    cb null

##=======================================================================

