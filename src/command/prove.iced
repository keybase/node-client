{ProofBase} = require './proof_base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_yn,prompt_remote_name} = require '../prompter'
{GenericWebSiteProofGen,TwitterProofGen,GithubProofGen} = require '../sigs'
{User} = require '../user'
{req} = require '../req'
assert = require 'assert'
session = require '../session'
S = require '../services'
{dict_union} = require '../util'
util = require 'util'
fs = require 'fs'

##=======================================================================

exports.Command = class Command extends ProofBase

  #----------

  OPTS : dict_union ProofBase.OPTS, {
    o : 
      alias : "output"
      help : "output proove text to file (rather than standard out)"
  }

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  command_name_and_opts : () ->
    config = 
      aliases : [ "proof" ]
      help : "add a proof of identity"
    name = "prove"
    return {name, config, @OPTS }

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
    if @rp? and (v = @rp[@service_name])? and @stub.single_occupancy()
      prompt = "You already have proven you are #{v} at #{@service_name}; overwrite? "
      await @check_exists_common prompt, defer err
    cb err

  #----------

  check_exists_2 : (cb) ->
    err = null
    if not(@stub.single_occupancy()) and (v = @rp?[@service_name])? and 
         (@remote_name_normalized in v)
      prompt = "You already have claimed ownership of #{@remote_name}; overwrite? "
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

  do_warnings : (cb) ->
    err = null
    if not (@argv.force) and (warns = @stub.get_warnings { @remote_name_normalized })? and warns.length
      for w in warns
        log.warn w
      prompt = "Proceed?"
      await prompt_yn { prompt, defval : false }, defer err, ok
      if not ok
        err = new E.CancelError "canceled"
    cb err

  #----------

  handle_post : (cb) ->
    esc = make_esc cb, "handle_post"
    log.console.log @gen.instructions()
    log.console.log ""
    if (f = @argv.output)?
      log.info "Writing proof to file '#{f}'..."
      await fs.writeFile f, @gen.proof_text, esc defer()
      log.info "Wrote proof to '#{f}'"
    else
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
    await @normalize_remote_name esc defer()
    await @check_exists_2 esc defer()
    await @do_warnings esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    await @handle_post esc defer()
    log.info "Success!"
    cb null

##=======================================================================

