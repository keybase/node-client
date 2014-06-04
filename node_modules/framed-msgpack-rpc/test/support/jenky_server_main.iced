{log,server,ReconnectTransport,Client} = require '../../src/main'

exports.main = () ->

  PORT = 8881

  # Since we're being forked, do this.  We shouldn't really
  # be doing this in "-d" mode to all.iced, but it's OK for now.
  log.set_default_level log.levels.WARN

  # this is a jenky server that crashes every time it does anything!
  # useful for testing the reconnecting client...
  class P_v1 extends server.Handler
    h_foo : (arg, res) ->
      res.result { y : arg.i + 2 }
      process.exit 0

  s = new server.ContextualServer 
    port : PORT
    classes :
      "P.1" : P_v1
  await s.listen defer err
  process.send { ok : true }

