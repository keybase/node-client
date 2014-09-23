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
{make_esc} = require 'iced-error'

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
      alias : 'passphrase'
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
    q:
      alias : "quiet"
      action : "storeTrue"
      help : "quiet mode; only show errors, suppress info and warnings"
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
      help : "specify an alternate gpg command"
    x :
      alias : 'proxy'
      help : 'specify a proxy server to all HTTPS requests'
    "proxy-ca-certs" :
      action : "append"
      help : "specify 1 or more CA certs (in a file)"
    O :
      alias : "no-gpg-options"
      action : "storeTrue"
      help : "disable the GPG options file for temporary keyring operations"
    M :
      alias : "merkle-checks"
      help : "check that users' chains are reflected in sitewide state, one of {none,soft,strict}; soft by default"
    "tor-proxy":
      help : "specify a Tor SOCKS proxy"
    "tor-hidden-address":
      help : "specify the Tor hidden address for keybase.io"
    "tor-leaky" :
      help : "override Tor strict mode"
      action: "storeTrue"
    S :
      alias : "tor-strict"
      help : "Don't show any user-identifiable information to server; might break some features"
      action : "storeTrue"
    T :
      alias : 'tor'
      action : "storeTrue"
      help : "enable Tor proxying with default settings; requires Tor Socks5 proxy on port 9050"


  #-------------------

  use_config : () -> true
  use_session : () -> false
  use_db : () -> true
  use_gpg : () -> true
  config_opts : () -> {}
  needs_configuration : () -> false
  needs_cookies : () -> false

  #-------------------

  make_outfile : (cb) ->
    await Outfile.open { target : @output_filename() }, defer err, file
    cb err, file

  #-------------------

  _init_pwmgr : () ->
    pwopts =
      password    : @password()
      salt        : @salt_or_email()
      interactive : @argv.interactive

    @pwmgr.init pwopts

  #-------------------

  password : () -> pick @argv.password, @config.password()

  #----------

  assertions : (cb) ->
    esc = make_esc cb, "Base::assertions"
    await @assert_configured esc defer()
    cb null

  #----------

  assert_configured : (cb) ->
    err = null
    if @needs_configuration() and not(env().is_configured())
      err = new E.NotConfiguredError "you're not logged in. Please run `keybase login` or `keybase join`"
    cb err

#=========================================================================
