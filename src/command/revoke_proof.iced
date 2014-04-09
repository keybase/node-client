{ProofBase} = require './proof_base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_yn} = require '../prompter'
{RevokeProofSigGen} = require '../sigs'
{User} = require '../user'
{req} = require '../req'
assert = require 'assert'
session = require '../session'
S = require '../services'
{constants} = require '../constants'
ST = constants.signature_types
{prompt_yn} = require '../prompter'
proofs = require 'keybase-proofs'
assert = require 'assert'

##=======================================================================

exports.Command = class Command extends ProofBase

  #----------

  command_name_and_opts : () ->
    config = 
      aliases : [  ]
      help : "revoke a proof of identity"
    name = "revoke-proof"
    return { name, config , OPTS : ProofBase.OPTS }

  #----------

  allocate_proof_gen : (cb) ->
    klass = RevokeProofSigGen
    await @me.gen_remote_proof_gen { klass, @sig_id }, defer err, @gen
    cb err

  #----------

  get_the_go_ahead : (cb) ->
    rp = @me.list_remote_proofs  {with_sig_ids : true } 
    err = null
    if not rp? or not (v = rp[@service_name])?
      err = E.NotFoundError "No proof found for service '#{@service_name}'"
    else if Array.isArray(v)
      d = {}
      names = []
      do_msg = false
      for e in v
        names.push e.name
        d[e.name] = e
      if names.length is 0
        err = new E.ArgsError "You don't have any #{@argv.service} proofs to revoke!"
      else if @remote_name? and not d[@remote_name]
        do_msg = true
        err = new E.ArgsError "You don't have a proof for '#{@remote_name}' to revoke"
      else if @remote_name
        @sig_id = d[@remote_name].sig_id
      else if not @remote_name and names.length > 1
        do_msg = true
        err = new E.ArgsError "need specifics"
      else
        to_prompt = 
          prompt : "Revoke your proof of #{v[0].name}"
          sig_id : v[0].sig_id
      if do_msg
        log.console.log "Please specify which proof to revoke; try one of:"
        log.console.log ""
        for n in names
          log.console.log "  keybase revoke-proof #{@service_name} #{n}"
        log.console.log ""
    else
      if @remote_name? and (@remote_name isnt v.name)
        err = E.ArgsError "Wrong name provided: you have a proof for '#{v.name}' and not '#{@remote_name}' @#{@service_name}"
      else if @remote_name?
        @sig_id = v.sig_id
      else 
        to_prompt = 
          prompt : "Revoke your proof of #{v.name} at #{@service_name}?"
          sig_id : v.sig_id
    if not err? and to_prompt?
      await prompt_yn { prompt : to_prompt.prompt, defval : false }, defer err, ok
      if err? then # noop 
      else if not ok
        err = new E.CancelError "Cancellation canceled! Did nothing."
      else
        @sig_id = to_prompt.sig_id
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_args esc defer()
    await session.login esc defer()
    await User.load_me { secret : true }, esc defer @me
    await @get_the_go_ahead esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    log.info "Success!"
    cb null

##=======================================================================

