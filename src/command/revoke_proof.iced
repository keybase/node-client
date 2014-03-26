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

  parse_args : (cb) ->
    err = null
    if (s = S.aliases[@argv.service[0].toLowerCase()])?
      @service_name = s
      @klass = S.classes[s]
      assert.ok @klass?
      @sub = new @klass {}
    else
      err = new E.UnknownServiceError "Unknown service: #{@argv.service[0]}"
    if not err? and (@remote_name = @argv.remote)? and not @stub.check_name(@remote_name)
      err = new E.ArgsError "Bad #{@argv.service[0]} name given: #{@remote_name}"

    cb err

  #----------

  get_the_go_ahead : (cb) ->
    rp = @me.list_remote_proofs  {with_sig_ids : true } 
    console.log rp
    err = null
    if rp? and (v = rp[@service_name]) 
      await prompt_yn { 
        prompt : "Revoke your proof of #{v} at #{@service_name}?", 
        defval : false }, defer err, ok
      if not err? and not ok
        err = new E.CancelError "Cancellation canceled! Did nothing."
    else
      err = E.NotFoundError "No proof found for service '#{@service_name}'"
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

