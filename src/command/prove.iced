{ProofBase} = require './proof_base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_yn,prompt_remote_name} = require '../prompter'
{User} = require '../user'
{req} = require '../req'
assert = require 'assert'
session = require '../session'
S = require '../services'
{dict_union} = require '../util'
util = require 'util'
fs = require 'fs'
proofs = require 'keybase-proofs'

##=======================================================================

exports.Command = class Command extends ProofBase

  #----------

  OPTS : dict_union ProofBase.OPTS, {
    o :
      alias : "output"
      help : "output proof text to file (rather than standard out)"
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
      @supersede = true
    cb err

  #----------

  check_exists_2 : (cb) ->
    err = null
    log.debug "+ check_exists_2"
    log.debug "| Remote proofs: #{JSON.stringify @rp}"
    log.debug "| Service name: #{@service_name}"
    log.debug "| Remote_name_normalized: #{@remote_name_normalized}"
    if not(@stub.single_occupancy()) and (v = @rp?[@service_name])? and
         (@remote_name_normalized in v)
      prompt = "You already have claimed ownership of #{@remote_name}; overwrite? "
      await @check_exists_common prompt, defer err
      @supersede = true
      log.debug '| supersede=true'
    log.debug "- check_exists_2"
    cb err

  #----------

  poll_server : (cb) ->
    arg =
      endpoint : "sig/posted"
      args :
        proof_id : @gen.proof_id
    await req arg, defer err, body
    res = if err? then false else body.proof_ok
    status = if err? then null else body.proof_res?.status
    cb err, res, status

  #----------

  do_prechecks : (cb) ->
    err = null
    if @argv.force then # noop
    else
      await @stub.do_precheck { @remote_name_normalized }, defer err
    cb err

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
      await fs.writeFile f, @gen.show_proof_text(), esc defer()
      log.info "Wrote proof to '#{f}'"
    else
      log.console.log @gen.show_proof_text()
    log.console.log ""
    prompt = true
    esc = make_esc cb, "Command::prompt"
    found = false
    first = true
    fail = true
    err = null

    i = 0
    while prompt
      await prompt_yn { prompt : "Check #{@gen.display_name()} #{if first then '' else 'again '}now?", defval : true }, esc defer prompt
      first = false
      if prompt
        await @poll_server esc defer found, status
        i++
        prompt = not found
        if found
          fail = false
          log.info "Success!"
        else
          retry = @gen.do_recheck(i)
          if not retry
            prompt = false
            fail = false
          else
            log.warn @gen.make_retry_msg status

    if not found and fail
      err = new E.ProofNotAvailableError "Proof wasn't available; we'll keep trying"

    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_args esc defer()
    await session.login esc defer()
    await User.load_me { secret : true, verify_opts : { show_perm_failures : true } }, esc defer @me
    await @check_exists_1 esc defer()
    await @prompt_remote_name esc defer()
    await @normalize_remote_name esc defer()
    await @check_exists_2 esc defer()
    await @do_prechecks esc defer()
    await @do_warnings esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    await @handle_post esc defer()
    cb null

##=======================================================================

