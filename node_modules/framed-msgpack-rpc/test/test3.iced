{server,Transport,Client} = require '../src/main'

## Do the same test as test1, a second time, must to make
## sure that we can rebind a second time...

PORT = 8881
s = null

class P_v1 extends server.Handler
  h_foo : (arg, res) -> res.result { y : arg.i + 2 }
  h_bar : (arg, res) -> res.result { y : arg.j * arg.k }

exports.init = (cb) ->
  
  s = new server.ContextualServer 
    port : PORT
    classes :
      "P.1" : P_v1
        
  await s.listen defer err
  cb err

exports.test1 = (T, cb) -> test_A T, cb
exports.test2 = (T, cb) -> test_A T, cb

test_A = (T, cb) -> 
  await T.connect PORT, "P.1", defer x, c
  if x 
    await T.test_rpc c, "foo", { i : 4 } , { y : 6 }, defer()
    await T.test_rpc c, "bar", { j : 2, k : 7 }, { y : 14}, defer()
    
    bad = "XXyyXX"
    await c.invoke bad, {}, defer err, res
    T.search err, /unknown method/, "method '#{bad}' should not be found"
    
    x.close()
    x = c = null
  cb()

exports.destroy = (cb) ->
  await s.close defer()
  s = null
  cb()
