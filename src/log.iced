baselog = require 'iced-logger'
rpc = require('framed-msgpack-rpc').log

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
    baselog[l] msg

  make_child : (d) -> return new Logger d

#=========================================================================

rpc.set_default_logger_class Logger

#=========================================================================

for k,v of baselog
  exports[k] = v

#=========================================================================

