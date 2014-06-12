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
assert = require 'assert'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    q : 
      alias : 'seqno'
      action : 'storeTrue'
      help : 'specify signature as a sequence number'

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  parse_args : (cb) ->
    key = @argv.sig[0]
    err = null
    if @argv.seqno
      if key.match /^\d+$/ then @seqno = parseInt(key,10)
      else err = new E.ArgsError "bad integer: #{key}"
    else if not key.match /^[A-Fa-f0-9]+$/ 
      err = new E.ArgsError "bad signature ID: #{key}"
    else if key.length < 4
      err = new E.ArgsError "bad signature ID #{key}; must provide at least a 4-char prefix"
    else
      @sig_id = key.toLowerCase()
    cb err

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "revoke a proof or signature"
      aliases : [ "revoke-sig" ]
    name = "revoke-signatures"
    sub = scp.addParser name, opts
    sub.addArgument [ "sig" ], { nargs : 1, help : "the ID or seqno of the sig the revoke" }
    add_option_dict sub, @OPTS
    return [ name ].concat opts.aliases

  #----------

  allocate_proof_gen : (cb) ->
    klass = RevokeProofSigGen
    await @me.gen_remote_proof_gen { klass, @sig_id }, defer err, @gen
    cb err

  #----------

  find_sig_by_prefix : (p) ->
    found = null
    err = null 
    for k,v of @me.sig_chain.index
      if k.indexOf(p) isnt 0 then # noop
      else if found? 
        err = new E.DuplicateError "Key '#{p}' matches more than one signature"
        found = null
        break
      else 
        found = v
    [err, found]

  #----------

  find_sig : (cb) ->
    key = @argv.sig[0]
    if @seqno then sig = @me.sig_chain.seq[@seqno]
    else [err, sig] = @find_sig_by_prefix @sig_id
    err = if err? then err
    else if not sig? then new E.NotFoundError "Signature not found (key=#{key})"
    else if sig.is_revoked() then new E.RevokedError "Signature already revoked"
    else if not sig.is_revocable() then new E.RevokeError "signature is not revocable"
    else null
    @sig_id = sig.sig_id() unless err?
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_args esc defer()
    await session.login esc defer()
    await User.load_me { secret : true, verify_opts : { show_perm_failures : true } }, esc defer @me
    await @find_sig esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    log.info "Success!"
    cb null

##=======================================================================

