kbpath = require 'keybase-path'
{join} = require 'path'
{constants} = require './constants'
{make_full_username,make_email} = require './util'
FN = constants.filenames
SRV = constants.server
fs = require 'fs'

##=======================================================================

class RunMode

  DEVEL : 0
  PROD : 1

  constructor : (s) ->
    t =
      devel : @DEVEL
      prod : @PROD

    [ @_v, @_name, @_chosen ] = if (s? and (m = t[s])?) then [m, s, true ]
    else [ @PROD, "prod", false ]

  is_devel : () -> (@_v is @DEVEL)
  is_prod : () -> @_v is @PROD

  toString : () -> @_name
  chosen : () -> @_chosen
  config_dir : () -> @_name

##=======================================================================

class Strictness

  NONE : 0
  SOFT : 1
  STRICT : 2

  constructor : (s, def = "soft") ->
    t =
      none : @NONE
      soft : @SOFT
      strict : @STRICT

    [ @_v, @_name, _chosen ] = if (s? and (m = t[s])?) then [ m, s, true ]
    else [ t[def], def, false ]

  is_soft : () -> (@_v is @SOFT)
  is_none : () -> (@_v is @NONE)
  is_strict : () -> (@_v is @STRICT)
  toString : () -> @_name
  chosen : () -> @_chosen

##=======================================================================

# Various obvious version #s
V1 = 1
V2 = 2

class Env

  # Load in all viable command line switching opts
  constructor : () ->
    @env = process.env
    @argv = null
    @config = null
    @session = null
    @_gpg_cmd = null
    @kbpath = kbpath.new_eng {
      hooks :
        get_home : (opts) => @_get_home opts
      name : "keybase"
    }

  set_config  : (c) -> @config = c
  set_session : (s) -> @session = s
  set_argv    : (a) -> @argv = a

  get_opt : ({env, arg, config, dflt}) ->
    co = @config?.obj()
    return env?(@env) or arg?(@argv) or (co? and config? co) or dflt?() or null

  get_config_dir : (version = V2) ->
    if (version is V1) then @kbpath.config_dir_v1() else @kbpath.config_dir()
  get_data_dir : () -> @kbpath.data_dir()
  get_cache_dir : () -> @kbpath.cache_dir()

  # In v1 of layout configuration, we just do the obvious thing, which is to use ~/.keybase/;
  # But in v2, we're trying to be compliant with the XDG specification for how to store
  # local files.
  maybe_fallback_to_layout_v1 : (cb) ->
    err = null
    res = false
    if not (@env.XDG_CONFIG_HOME or @env.XDG_CACHE_HOME or @env.XDG_DATA_HOME)
      old_config = @get_config_filename(V1)
      await fs.stat old_config, defer err, stat
      if not err? and stat?.isFile()
        @kbpath = @kbpath.fallback_to_v1()
        res = true
      else if err.code is 'ENOENT' then err = null
    cb err, res

  get_port   : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_PORT
      arg    : (a) -> a.port
      config : (c) -> c.server?.port
      dflt   : ( ) -> SRV.port

  get_config_filename : (version = V2) ->
    @get_opt
      env    : (e) -> e.KEYBASE_CONFIG_FILE
      arg    : (a) -> a.config
      dflt   : ( ) => join @get_config_dir(version), FN.config_file

  get_session_filename : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_SESSION_FILE
      arg    : (a) -> a.session_file
      config : (c) -> c?.files?.session
      dflt   : ( ) => join @get_cache_dir(), FN.session_file

  get_db_filename : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_DB_FILE
      arg    : (a) -> a.db_file
      config : (c) -> c?.files?.db
      dflt   : ( ) => join @get_data_dir(), FN.db_file

  get_nedb_filename : () ->
    @get_opt
      config : (c) -> c?.files?.nedb
      dflt   : ( ) => join @get_home(), FN.config_dir, FN.nedb_file

  get_tmp_keyring_dir : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_TMP_KEYRING_DIR
      arg    : (a) -> a.tmp_keyring_dir
      config : (c) -> c?.files?.tmp_keyring_dir
      dflt   : ( ) => join @get_cache_dir(), FN.tmp_keyring_dir

  get_preserve_tmp_keyring : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_PRESERVE_TMP_KEYRING
      arg    : (a) -> a.preserve_tmp_keyring
      dflt   : ( ) -> false

  get_host   : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_HOST
      arg    : (a) -> a.host
      config : (c) -> c.server?.host
      dflt   : ( ) -> SRV.host

  get_debug  : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_DEBUG
      arg    : (a) -> a.debug
      config : (c) -> c.run?.d
      dflt   : ( ) -> false

  get_no_tls : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_NO_TLS
      arg    : (a) -> a.no_tls
      config : (c) -> c.server?.no_tls
      dflt   : ( ) -> SRV.no_tls

  get_api_uri_prefix : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_API_URI_PREFIX
      arg    : (a) -> a.api_uri_prefix
      config : (c) -> c.server?.api_uri_prefix
      dflt   : ( ) -> SRV.api_uri_prefix

  get_run_mode : () ->
    unless @_run_mode
      raw = @get_opt
        env    : (e) -> e.KEYBASE_RUN_MODE
        arg    : (a) -> a.m
        config : (c) -> c.run?.mode
        dflt   : null
      @_run_mode = new RunMode raw
    return @_run_mode

  get_log_level : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_LOG_LEVEL
      arg    : (a) -> a.l
      config : (c) -> c.run?.log_level
      dflt   : -> null

  get_passphrase : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_PASSPHRASE
      arg    : (a) -> a.passphrase
      config : (c) -> c.user?.passphrase
      dflt   : -> null

  get_username : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_USERNAME
      arg    : (a) -> a.username
      config : (c) -> c.user?.name
      dflt   : -> null

  is_me : (u2) ->
    u2? and (u1 = @get_username())? and (u2.toLowerCase() is u1.toLowerCase())

  get_uid : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_UID
      arg    : (a) -> a.uid
      config : (c) -> c.user?.id
      dflt   : -> null

  get_email : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_EMAIL
      arg    : (a) -> a.email
      config : (c) -> c.user?.email
      dflt   : -> null

  _get_home : ({null_ok}) ->
    @get_opt
      env    : (e) -> e.KEYBASE_HOME_DIR
      arg    : (a) -> a.homedir
      dflt   : -> null

  get_home : (opts) -> @kbpath.home(opts)

  get_home_gnupg_dir : (null_ok = false) ->
    ret = @get_home { null_ok : true }
    ret = join(ret, ".gnupg") if ret?
    return ret

  get_gpg_cmd : () ->
    @_gpg_cmd or @get_opt
      env    : (e) -> e.KEYBASE_GPG
      arg    : (a) -> a.gpg
      config : (c) -> c.gpg
      dflt   : -> null

  set_gpg_cmd : (c) -> @_gpg_cmd = c

  get_proxy : () ->
    @get_opt
      env    : (e) -> e.http_proxy or e.https_proxy
      arg    : (a) -> a.proxy
      config : (c) -> c.proxy?.url
      dflt   : -> null

  get_tor : () ->
    @get_opt
      env    : (e) -> e.TOR_ENABLED
      arg    : (a) -> a.tor
      config : (c) -> c.tor?.enabled
      dflt   : -> false

  get_tor_strict : () ->
    @get_opt
      env    : (e) -> e.TOR_STRICT
      arg    : (a) -> a.tor_strict
      config : (c) -> c.tor?.strict
      dflt   : -> false

  get_tor_leaky : () ->
    @get_opt
      env    : (e) -> e.TOR_LEAKY
      arg    : (a) -> a.tor_leaky
      config : (c) -> c.tor?.leaky
      dflt   : -> false

  get_tor_proxy : (null_ok) ->
    @host_split @get_opt
      env    : (e) -> e.TOR_PROXY
      arg    : (a) -> a.tor_proxy
      config : (c) -> c.tor?.proxy
      dflt   : -> if null_ok then null else constants.tor.default_proxy

  host_split : (s) ->
    ret = if not s? then s
    else
      parts = s.split /:/
      hostname = parts[0]
      port = if parts.length > 1 then parts[1] else null
      {hostname, port}
    ret

  get_tor_hidden_address : (null_ok) ->
    @host_split @get_opt
      env    : (e) -> e.TOR_HIDDEN_ADDRESS
      arg    : (a) -> a.tor_hidden_address
      config : (c) -> c.tor?.hidden_address
      dflt   : -> if null_ok then null else constants.tor.hidden_address

  get_proxy_ca_certs : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_PROXY_CA_CERTS
      arg    : (a) -> a.proxy_ca_certs
      config : (c) -> c.proxy?.ca_certs
      dflt   : -> null

  get_loopback_port_range : () ->
    parse_range = (s) ->
      if not s? then null
      else if not (m = s.match /^(\d+)-(\d+)$/) then (parseInt(i,10) for i in m[1...])
      else null

    @get_opt
      env    : (e) -> parse_range e.KEYBASE_LOOPBACK_PORT_RANGE
      arg    : (a) -> parse_range a.loopback_port_range
      config : (c) -> c.loopback_port_range
      dflt   : -> constants.loopback_port_range

  get_no_gpg_options :() ->
    @get_opt
      env    : (e) -> e.KEYBASE_NO_GPG_OPTIONS
      arg    : (a) -> a.no_gpg_options
      config : (c) -> c.no_gpg_options
      dflt   :     -> false

  get_merkle_checks : () ->
    unless @_merkle_mode
      raw = @get_opt
        env    : (e) -> e.KEYBASE_MERKLE_CHECKS
        arg    : (a) -> a.merkle_checks
        config : (c) -> c.merkle_checks
        dflt   :     -> false
      @_merkle_mode = new Strictness raw, (if @is_test() then 'strict' else 'soft')
    return @_merkle_mode

  get_merkle_key_fingerprints : () ->
    split = (x) -> if x? then x.split(/:,/) else null
    @get_opt
      env    : (e) -> split e.KEYBASE_MERKLE_KEY_FINGERPRINTS
      arg    : (a) -> split a.merkle_key_fingerprint
      config : (c) -> c?.keys?.merkle
      dflt   :     => if @is_test() then constants.testing_keys.merkle else constants.keys.merkle

  get_no_color : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_NO_COLOR
      arg    : (a) -> a.no_color
      config : (c) -> c.no_color
      dflt   :     -> false

  get_args : () -> @argv._
  get_argv : () -> @argv

  #---------------

  is_configured : () -> @get_username()?

  #---------------

  is_test : () -> (@get_run_mode().is_devel()) or (@get_host() in [ 'localhost', '127.0.0.1' ])

  #---------------

  keybase_email : () -> make_email @get_username()

  #---------------

  keybase_full_username : () -> make_full_username @get_username()

  #---------------

  init_home_scheme : (cb) ->


  #---------------

  make_pgp_uid : () -> {
    username : @keybase_full_username()
    email : @keybase_email()
  }

##=======================================================================

_env = null
exports.init_env = (a) -> _env = new Env
exports.env      = ()  -> _env

