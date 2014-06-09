{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
C = require('../constants').constants
ST = C.signature_type
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
{CryptocurrencySigGen} = require './sigs'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    f : 
      alias : 'force'
      action : 'storeTrue'
      help : 'force overwrite, revoking the old for this address'

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  add_subcommand_parse : (scp) ->
    opts = 
      aliases : []
      help : "add a signed cryptocurrency address to your profile"
    name = "btc"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "btc" ], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #----------

  parse_args : (cb) ->
    [err,{version}] = bitcoyne.address.check(@argv.btc[0])
    if err?
      err = new E.BadCryptocurrencyAddress "Bad BTC address: #{err.message}"
    else if version not in ACCTYPES
      err = new E.UnsupportedCryptocurrencyAddress "Only support bitcoin addresses at current"
    else
      @address_version = version
    cb err

  #----------

  check_exists : (cb) ->
    address_types = @me.sig_chain.table[ST.CRYPTOCURRENCY]
    links = (link for c in C.ACCTYPES when (link = address_types[c])? )
    es = if links.length is 1 then '' else 'es'
    a = (link.body().cryptocurrency.address for s in sigs)
    prompt = "You already have registed address#{s} #{a}; revoke and proceed? "
    await prompt_yn { prompt, defval : false }, defer err, ok
    if err? then # noop
    else if not ok
      err = new E.ProofExistsError "Addresses already exist"
    else
      @revoke_sig_ids = (link.id for link in links)
    cb err

  #----------

  allocate_proof_gen : (cb) ->
    klass = CryptocurrencySigGen
    # Only BTC is supported just yet...
    cryptocurrency = { address : @argv.btc[0], type : 'bitcoin' }
    arg = { @revoke_sig_ids, cryptocurrency } 
    await @me.gen_sig_base { klass, arg }, defer err, @gen
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
    cb null

##=======================================================================

