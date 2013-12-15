
log = require '../log'
{PasswordManager} = require '../pw'
{base58} = require '../basex'
crypto = require 'crypto'
myfs = require '../fs'
fs = require 'fs'
{rmkey} = require '../util'
{add_option_dict} = require './argparse'
{Infile, Outfile} = require '../file'
{EscOk} = require 'iced-error'
{E} = require '../err'
{constants} = require '../constants'
{join} = require 'path'
ProgressBar = require 'progress'
FN = constants.filenames
SRV = constants.server
SC = constants.security
triplesec = require 'triplesec'
req = require '../req'
{env} = require '../env'

#=========================================================================

pick = (args...) ->
  for a in args
    return a if a?
  return null

#=========================================================================

exports.Base = class Base

  #-------------------

  constructor : () ->

  #-------------------

  set_argv : (a) -> @argv = a

  #-------------------

  @OPTS :
    p : 
      alias : 'passhrase'
      help : 'passphrase used to log into keybase'
    c : 
      alias : 'config'
      help : "a configuration file (#{join '~', FN.config_dir, FN.config_file})"
    i : 
      alias : "interactive"
      action : "storeTrue"
      help : "interactive mode"
    d:
      alias: "debug"
      action : "storeTrue"
      help : "debug mode"
    port :
      help : 'which port to connect to'
    "no-tls" :
      action : "storeTrue"
      help : "turn off HTTPS/TLS (on by default)"
    "host" :
      help : 'which host to connect to'
    "api-uri-prefix" :
      help : "the API prefix to use (#{SRV.api_uri_prefix})"

  #-------------------

  use_config : () -> true
  use_session : () -> false
  config_opts : () -> {}

  #-------------------

  make_outfile : (cb) -> 
    await Outfile.open { target : @output_filename() }, defer err, file
    cb err, file

  #-------------------

  init2 : ({infile, outfile, enc}, cb) ->
    esc = new EscOk cb
    await @init esc.check_ok defer(), E.InitError
    if infile
      @infn = @argv.file[0]
      await Infile.open @infn, esc.check_err defer @infile
    if outfile
      await @make_outfile esc.check_err defer @outfile
    if enc and (@crypto_mode() isnt constants.crypto_mode.NONE)
      new_key = (@crypto_mode() is constants.crypto_mode.ENC)
      await @pwmgr.derive_keys new_key, esc.check_non_null defer @keys

    # An engine of some sort should always be defined, something to pump
    # data from the input to the output.  Might run through filters, etc...
    @eng = @make_eng { @keys, @infile, @outfile }
    
    cb true

  #-------------------

  _gen_pwh : ({passphrase, salt}, cb) ->

    @enc = new triplesec.Encryptor { 
      key : new Buffer(passphrase, 'utf8')
      verion : SC.triplesec.version
    }

    bar = null
    prev = 0
    progress_hook = (obj) ->
      if obj.what isnt "scrypt" then #noop
      else 
        bar or= new ProgressBar "- run scrypt [:bar] :percent", { 
          width : 35, total : obj.total 
        }
        bar.tick(obj.i - prev)
        prev = obj.i

    extra_keymaterial = SC.pwh.derived_key_bytes + SC.openpgp.derived_key_bytes
    await @enc.resalt { salt, extra_keymaterial, progress_hook }, defer err, km
    unless err?
      @salt = @enc.salt.to_hex()
      @pwh = km.extra[0...SC.pwh.derived_key_bytes].toString('hex')
    cb err, @pwh, @salt


  #-------------------

  _login : (cb) ->
    ok = false
    err = null
    await @_session_check defer err, ok
    until ok
      await @_login_iter defer err, ok
    cb err, ok

  #-------------------

  _write_session : (cb) ->
    s = env().session
    s.set "session", req.cookies().session
    await s.write defer err
    cb err

  #-------------------

  _init_pwmgr : () ->
    pwopts =
      password    : @password()
      salt        : @salt_or_email()
      interactive : @argv.interactive

    @pwmgr.init pwopts

  #-------------------

  password : () -> pick @argv.password, @config.password()

#=========================================================================

