{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_yn,prompt_remote_name} = require '../prompter'
{TwitterProofGen,GithubProofGen} = require '../sigs'
{User} = require '../user'
{req} = require '../req'
assert = require 'assert'
session = require '../session'
S = require '../services'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "proof" ]
      help : "add a proof of identity"
    name = "prove"
    sub = scp.addParser name, opts
    sub.addArgument [ "service" ], { nargs : 1, help: "the name of service" }
    sub.addArgument [ "remote_name"], { nargs : "?", help : "username at that service" }
    return opts.aliases.concat [ name ]

  #----------

  prompt_remote_name : (cb) ->
    svc = @argv.service[0]
    err = null
    unless (ret = @argv.remote_name)?
      await prompt_remote_name @stub.prompter(), defer err, ret
    @remote_username = ret
    cb err, ret

  #----------

  allocate_proof_gen : (cb) ->
    klass = S.classes[@service_name]
    assert.ok klass?
    await @me.gen_remote_proof_gen { klass, @remote_username }, defer err, @gen
    cb err

  #----------

  parse_args : (cb) ->
    err = null
    if (s = S.aliases[@argv.service[0].toLowerCase()])?
      @service_name = s
      @klass = @TABLE[s]
      assert.ok @klass?
      @stub = new @klass {}
    else
      err = new E.UnknownServiceError "Unknown service: #{@argv.service[0]}"
    cb err

  #----------

  check_exists_common : (prompt, cb) ->
    err = null
    await prompt_yn { prompt, defval : false }, defer err, ok
    if not err? and not ok
      err = new E.ProofExistsError "Proof already exists"
    cb err

  #----------

  check_exists_1 : (cb) ->
    @rp = @me.list_remote_proofs() 
    err = null
    if rp? and (v = @rp[@service_name]) and @stub.single_occupancy()
      prompt = "You already have proved you are #{v} at #{@service_name}; overwrite? "
      await @check_exists_common prompt, defer err
    cb err

  #----------

  check_exists_2 : (cb) ->
    err = null
    if not(@stub.single_occupancy()) and (@normalized_remote_name in @rp[@service_name])
      prompt = "You already have proved ownership of #{@remote_name}; overwrite? "
      await @check_exists_common prompt, defer err
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
    log.console.log @gen.instructions()
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
    await @parse_args esc defer()
    await session.login esc defer()
    await User.load_me { secret : true }, esc defer @me
    await @check_exists_1 esc defer()
    await @prompt_remote_name esc defer()
    await @check_exists_2 esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    await @handle_post esc defer()
    log.info "Success!"
    cb null

##=======================================================================

