
colors = require 'colors'
winston = require 'winston'
rpc = require('framed-msgpack-rpc').log

#=========================================================================

_daemonize = false
c = (fn, msg) -> if _daemonize then msg else fn msg
bold_red = (x) -> colors.bold colors.red x

#=========================================================================

exports.log = log = (msg) -> info msg
exports.warn = warn = (msg) -> winston.warn(c(colors.magenta,msg))
exports.error = error = (msg) -> winston.error(c(bold_red, msg))
exports.info = info = (msg) -> winston.info(c(colors.green,msg))
exports.debug = info = (msg) -> winston.debug msg

#=========================================================================

exports.daemonize = (file) ->
  _daemonize = true
  winston.add winston.transports.File, { filename : file , json : false }
  winston.remove winston.transports.Console

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
    exports[l] msg

  make_child : (d) -> return new Logger d

#=========================================================================

rpc.set_default_logger_class Logger

#=========================================================================

