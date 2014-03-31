{server,Transport,Client,debug} = require '../src/main'

# The same as test9, but over Unix Domain sockets, and not over
# TCP Ports...

s = null
SOCK = "/tmp/rpc.test10.sock"

##-----------------------------------------------------------------------

class P_v1 extends server.Handler
  h_foo : (arg, res) -> res.result { y : arg.i + 2 }
  h_bar : (arg, res) -> res.result { y : arg.j * arg.k }

##-----------------------------------------------------------------------

exports.init = (cb) ->
  
  s = new server.ContextualServer 
    path : SOCK
    classes :
      "P.1" : P_v1

  s.set_debugger new debug.Debugger debug.constants.flags.LEVEL_4
        
  await s.listen defer err
  cb err

##-----------------------------------------------------------------------

exports.test1 = (T, cb) -> test_A T, cb
exports.test2 = (T, cb) -> test_A T, cb

##-----------------------------------------------------------------------

test_A = (T, cb) -> 
  await T.connect SOCK, "P.1", defer x, c
  if x 
    await T.test_rpc c, "foo", { i : 4 } , { y : 6 }, defer()
    await T.test_rpc c, "bar", { j : 2, k : 7 }, { y : 14}, defer()
    
    bad = "XXyyXX"
    await c.invoke bad, {}, defer err, res
    T.search err, /unknown method/, "method '#{bad}' should not be found"
    
    x.close()
    x = c = null
  cb()

##-----------------------------------------------------------------------
exports.destroy = (cb) ->
  await s.close defer()
  s = null
  cb()
