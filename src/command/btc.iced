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
    f : 
      alias : 'force'
      action : 'storeTrue'
      help : 'force overwrite, revoking any old addresses'

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ 'bitcoin' ]
      help : "add a signed cryptocurrency address to your profile"
    name = "btc"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "btc" ], { nargs : 1, help :"the address to sign and publicly post"  }
    return opts.aliases.concat [ name ]

  #----------

  parse_args : (cb) ->
    [err,ret] = bitcoyne.address.check(@argv.btc[0])
    if err?
      err = new E.BadCryptocurrencyAddressError "Bad BTC address: #{err.message}"
    else if not ret?.version?
      err = new E.BadCryptocurrencyAddressError "Bad BTC address; no type found"
    else if not (ret.version in ACCTYPES)
      err = new E.UnsupportedCryptocurrencyAddressError "Only support bitcoin addresses at current"
    else
      @address_version = ret.version
    cb err

  #----------

  check_exists : (cb) ->
    address_types = @me.sig_chain?.table?.get(ST.CRYPTOCURRENCY) or null
    links = (link for c in ACCTYPES when (link = address_types?.get(c))?)
    addresses = (link.body().cryptocurrency.address for link in links)
    if not addresses.length
      err = null
    else if @argv.btc[0] in addresses
      err = new E.DuplicateError "you've already signed BTC address '#{@argv.btc[0]}'"
    else if not @argv.force
      if addresses.length is 1
        prompt = "You already have registered address #{addresses[0]}; revoke and proceed?"
      else
        prompt = "You already have registered addresses [#{addresses.join(',')}]; revoke and proceed?"
      await prompt_yn { prompt, defval : false }, defer err, ok
      if err? then # noop
      else if not ok
        m = if addresses.length is 1 then 'Address already exists'
        else "Addresses already exist"
        err = new E.ProofExistsError m

    unless err?
      @revoke_sig_ids = (link.sig_id() for link in links)
      
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
    log.info "Success!"
    cb null

##=======================================================================

