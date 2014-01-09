
{home} = require './path'
{join} = require 'path'
{constants} = require './constants'
FN = constants.filenames
SRV = constants.server

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

class Env

  # Load in all viable command line switching opts
  constructor : () ->
    @env = process.env
    @argv = null
    @config = null
    @session = null

  set_config  : (c) -> @config = c
  set_session : (s) -> @session = s
  set_argv    : (a) -> @argv = a

  get_opt : ({env, arg, config, dflt}) ->
    co = @config?.obj()
    return env?(@env) or arg?(@argv) or (co? and config? co) or dflt?() or null

  get_port   : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_PORT
      arg    : (a) -> a.port
      config : (c) -> c.server?.port
      dflt   : ( ) -> SRV.port

  get_config_filename : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_CONFIG_FILE
      arg    : (a) -> a.config
      dflt   : ( ) -> join home(), FN.config_dir, FN.config_file

  get_session_filename : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_SESSION_FILE
      arg    : (a) -> a["session-file"]
      config : (c) -> c?.files?.session
      dflt   : ( ) -> join home(), FN.config_dir, FN.session_file

  get_db_filename : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_DB_FILE
      arg    : (a) -> a["db-file"]
      config : (c) -> c?.files?.db
      dflt   : ( ) -> join home(), FN.config_dir, FN.db_file

  get_tmp_keyring_dir : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_TMP_KEYRING_DIR
      arg    : (a) -> a["tmp-keyring-dir"]
      config : (c) -> c?.files?.tmp_keyring_dir
      dflt   : ( ) -> join home(), FN.config_dir, FN.tmp_keyring_dir

  get_tmp_gpg_sec_keyring : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_TMP_GPG_SEC_KEYRING
      arg    : (a) -> a["tmp-gpg-sec-keyring"]
      config : (c) -> c?.files?.tmp_gpg?.sec_keyring
      dflt   : ( ) -> join home(), FN.config_dir, FN.tmp_gpg.sec_keyring

  get_tmp_gpg_pub_keyring : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_TMP_GPG_SEC_KEYRING
      arg    : (a) -> a["tmp-gpg-pub-keyring"]
      config : (c) -> c?.files?.tmp_gpg?.pub_keyring
      dflt   : ( ) -> join home(), FN.config_dir, FN.tmp_gpg.pub_keyring

  get_tmp_gpg_trustdb : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_TMP_GPG_TRUSTDB
      arg    : (a) -> a["tmp-gpg-trustdb"]
      config : (c) -> c?.files?.tmp_gpg?.trustdb
      dflt   : ( ) -> join home(), FN.config_dir, FN.tmp_gpg.trustdb

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
      arg    : (a) -> a["no-tls"]
      config : (c) -> c.server?.no_tls
      dflt   : ( ) -> SRV.no_tls

  get_api_uri_prefix : () ->
    @get_opt
      env    : (e) -> e.KEYBASE_API_URI_PREFIX
      arg    : (a) -> a["api-uri-prefix"]
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

  get_key_server : () ->
    self = @
    @get_opt
      env    : (e) -> e.KEYBASE_KEY_SERVER
      arg    : (a) -> a.key_server
      config : (c) -> c.key_server
      dflt   : -> "hkp://#{self.get_host()}:#{self.get_port()}"

  get_args : () -> @argv._
  get_argv : () -> @argv

##=======================================================================

_env = null
exports.init_env = (a) -> _env = new Env 
exports.env      = ()  -> _env

