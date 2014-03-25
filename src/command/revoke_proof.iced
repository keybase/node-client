{Base} = require './base'
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
  needs_configuration : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [  ]
      help : "revoke a proof of identity"
    name = "revoke-proof"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "service" ], { nargs : 1, help: "the name of service" }
    return opts.aliases.concat [ name ]

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
    else
      err = new E.UnknownServiceError "Unknown service: #{@argv.service[0]}"
    cb err

  #----------

  get_the_go_ahead : (cb) ->
    rp = @me.list_remote_proofs() 
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

