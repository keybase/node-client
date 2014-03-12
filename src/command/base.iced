
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

  constructor : (@parent) ->
    @batch = false # We sometimes turn this on if we're reading from stdin

  #-------------------

  set_argv : (a) -> 
    @argv = a
    return null

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
    C:
      alias : "no-color"
      action : "storeTrue"
      help : "disable logging colors"
    port :
      help : 'which port to connect to'
    "no-tls" :
      action : "storeTrue"
      help : "turn off HTTPS/TLS (on by default)"
    "host" :
      help : 'which host to connect to'
    "api-uri-prefix" :
      help : "the API prefix to use (#{SRV.api_uri_prefix})"
    B :
      alias : "batch"
      action : "storeTrue"
      help : "batch mode; disable all prompts"
    "preserve-tmp-keyring" :
      action : "storeTrue"
      help : "preserve the temporary keyring; don't clean it up"
    "homedir" :
      help : "specify a non-standard home directory; look for GPG keychain there"
    g : 
      alias : "gpg"
      help : "specify an altnernate gpg command"
    x : 
      alias : 'proxy'
      help : 'specify a proxy server to all HTTPS requests'
    "proxy-ca-certs" :
      action : "append"
      help : "specify 1 or more CA certs (in a file)"

  #-------------------

  use_config : () -> true
  use_session : () -> false
  use_db : () -> true
  use_gpg : () -> true
  config_opts : () -> {}
  set_proxy_ca_certs : (ca) -> 

  #-------------------

  make_outfile : (cb) -> 
    await Outfile.open { target : @output_filename() }, defer err, file
    cb err, file

  #-------------------

  _login : (cb) ->
    ok = false
    err = null
    await @_session_check defer err, ok
    until ok
      await @_login_iter defer err, ok
    cb err, ok

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

