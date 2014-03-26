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
    opts = 
      aliases : [  ]
      help : "revoke a proof of identity"
    name = "revoke-proof"
    return { name, opts }

  #----------

  allocate_proof_gen : (cb) ->
    klass = RevokeProofSigGen
    typ = proofs.constants.proof_types[@service_name]
    if not (sig_id = @me.sig_chain?.table?[ST.REMOTE_PROOF]?[typ]?.sig_id())?
      err = new E.NotFoundError "Didn't find a valid signature; no sig id!"
    else
      await @me.gen_remote_proof_gen { klass, sig_id }, defer err, @gen
    cb err

  #----------

  get_the_go_ahead : (cb) ->
    rp = @me.list_remote_proofs  {with_sig_ids : true } 
    console.log rp
    err = null
    if not rp? or not (v = rp[@service_name])?
      err = E.NotFoundError "No proof found for service '#{@service_name}'"
    else if Array.isArray(v)

    else
      if @remote_name? and (@remote_name isnt v.name)
        err = E.ArgsError "Wrong name provided: you have a proof for '#{v.name}' and not '#{@remote_name}' @#{@service_name}"
      else if not @remote_name?
        await prompt_yn { 
          prompt : "Revoke your proof of #{v} at #{@service_name}?", 
          defval : false }, defer err, ok
        if not err? and not ok
          err = new E.CancelError "Cancellation canceled! Did nothing."
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

