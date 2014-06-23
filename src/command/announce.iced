{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
C = require('../constants').constants
ST = C.signature_types
ACCTYPES = C.allowed_cryptocurrency_types
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
proofs = require 'keybase-proofs'
bitcoyne = require 'bitcoyne'
{CryptocurrencySigGen} = require '../sigs'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    j :
      alias : 'json'
      action : 'storeTrue'
      help : 'interpret the announcement as JSON object'
    e :
      alias : 'encode'
      action : 'storeTrue'
      help : 'encode the announcement with base64-encoding'
    f : 
      alias : 'file'
      help : 'Specify a file as the announcment'
    m:
      alias : 'message'
      help : 'Specify a message as the announcement"'

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  #----------
  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ ]
      help : "make an announcement, stored to your signature chain"
    name = "announce"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return opts.aliases.concat [ name ]

  #----------

  parse_args : (cb) ->
    err = null
    if @argv.e and @argv.j
      err = new E.ArgsError "can't specify both -j and -e"
    else if @argv.f and @argv.m
      err = new E.ArgsError "can't specify both -f and -m"
    cb err

  #----------

  allocate_proof_gen : (cb) ->
    klass = AnnouncementSigGen
    # Only BTC is supported just yet...
    cryptocurrency = { address : @argv.btc[0], type : 'bitcoin' }
    arg = { @revoke_sig_ids, cryptocurrency } 
    await @me.gen_sig_base { klass, arg }, defer err, @gen
    cb err

  #----------

  load_announcement : (cb) ->

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_args esc defer()
    await session.login esc defer()
    await User.load_me { secret : true }, esc defer @me
    await @load_announcement esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    log.info "Success!"
    cb null

##=======================================================================

