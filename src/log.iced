
colors = require 'colors'
rpc = require('framed-msgpack-rpc').log

#=========================================================================

bold_red = (x) -> colors.bold colors.red x

#=========================================================================

class Env 
  constructor : ( {@use_color, @level}) ->
  set_level : (l) -> @level = l
  set_use_color : (c) -> @use_color = c

#=========================================================================

repeat = (c, n) -> (c for [0...n]).join('')

class Level
  constructor : ({@level, @color_fn, @prefix}) ->
    @_i = 0

  log : (env, msg) ->
    if env.level <= @level
      lines = msg.split "\n"
      for line in lines
        @_log_line env, line

  _handle_nesting : (line) ->
    if line.match(/^[+|-] /)
      prefix = switch line[0]
        when '+' 
          @_i++
          (repeat '+', @_i)
        when '-'
          p = (repeat '-', @_i)
          @_i = 0 if --@_i < 0
          p 
        when '|'
          (repeat '|', @_i)
      line = [ prefix, line[2...] ].join(' ')
    line

  _log_line : (env, line) ->
    line = @_handle_nesting line

    line = [ (@prefix + ":"), line ].join(' ')
    line = @color_fn line if @color_fn? and env.use_color
    @__log_line line

  __log_line : (x) -> console.log x

#=========================================================================

default_levels = 
  debug : new Level { level : 0, color_fn : colors.blue,    prefix : "debug" }
  info  : new Level { level : 1, color_fn : colors.green,   prefix : "info"  }
  warn  : new Level { level : 2, color_fn : colors.magenta, prefix : "warn"  }
  error : new Level { level : 3, color_fn : bold_red,       prefix : "error" }

#=========================================================================

class Package

  constructor : ({env,config,console}) ->
    @_env = env
    @_config = config
    @_console = console
    for key,val of config
      ((k,v) =>
        @[k] = (m) => v.log(@_env, m)
        @[k.toUpperCase()] = v.level
      )(key, val)

  env : -> @_env

  export_to : (exports) ->
    for k,v of @_config
      exports[k] = @[k]
    exports.package = () => @
    exports.console = @_console

#=========================================================================

_package = null

exports.init = init = ({env,config, console}) ->
  (_package = new Package { env, config, console }).export_to exports

init { 
  env    : new Env({ use_color : true, level : default_levels.info.level }),
  config : default_levels
  console : console
}

#=========================================================================

# Make a winston-aware version of the RPC logger
class Logger extends rpc.Logger

  _log : (m, l, ohook) ->
    parts = []
    parts.push @prefix if @prefix?
    parts.push m
    msg = parts.join " "
    map = 
      D : "debug"
      I : "info"
      W : "warn"
      E : "error"
      F : "fatal"
    l = map[l] or "warn"
    _pacakage[l] msg

  make_child : (d) -> return new Logger d

#=========================================================================

rpc.set_default_logger_class Logger

#=========================================================================

