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

##=======================================================================

exports.Command = class Command extends Base

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
    sub.addArgument [ "service" ], { nargs : 1, help: "the name of service" }
    return opts.aliases.concat [ name ]

  #----------

  allocate_proof_gen : (cb) ->
    klass = RevokeProofSigGen
    await @me.gen_remote_proof_gen { klass }, defer err, @gen
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

  check_exists : (cb) ->
    rp = @me.list_remote_proofs() 
    err = null
    if rp? and (v = rp[@service_name]) 
      await prompt_yn { 
        prompt : "You already have proved you are #{v} at #{@service_name}; overwrite? ", 
        defval : false }, defer err, ok
      if not err? and not ok
        err = new E.ProofExistsError "Proof already exists"
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_args esc defer()
    await session.login esc defer()
    await User.load_me { secret : true }, esc defer @me
    await @check_exists esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    await @handle_post esc defer()
    log.info "Success!"
    cb null

##=======================================================================

