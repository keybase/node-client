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
  constructor : ({@argv, @config}) ->
    @env = process.env

  get_opt : ({env, arg, config, dflt}) ->
    co = @config.obj
    return env?(@env) or arg?(@argv) or (co? and config? co) or dflt?() or null

  get_port   : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_PORT
      arg    : (a) -> a.p
      config : (c) -> c.server?.port
      dflt   : ( ) -> 443

  get_host   : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_HOST
      arg    : (a) -> a.h
      config : (c) -> c.server?.host
      dflt   : ( ) -> "keybase.io"

  get_debug  : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_DEBUG
      arg    : (a) -> a.d
      config : (c) -> c.run?.d
      dflt   : ( ) -> false

  get_no_tls : ( ) ->
    @get_opt
      env    : (e) -> e.KEYBASE_NO_TLS
      arg    : (a) -> a.T
      config : (c) -> c.server?.no_tls
      dflt   : ( ) -> false

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

  get_args : () -> @argv._
  get_argv : () -> @argv

##=======================================================================

_env = null
exports.make = (f) -> _env = new Env f
exports.get  = () -> _env

