{server,transport,client} = require '../src/main'

PORT = 8881

s = null

exports.init = (cb) ->
  
  s = new server.Server
    port : PORT
    programs :
      "P.1" :
        foo : (arg, res) -> res.result { y : arg.i + 2 }
        bar : (arg, res) -> res.result { y : arg.j * arg.k }
        
  await s.listen defer err
  cb err

exports.test1 = (T, cb) -> test_A T, cb
exports.test2 = (T, cb) -> test_A T, cb

test_A = (T, cb) -> 
  x = new transport.Transport { port : PORT, host : "-" }
  await x.connect defer err
  if err?
    console.log "Failed to connect in Transport..."
  else
    ok = false
    c = new client.Client x, "P.1"
    await T.test_rpc c, "foo", { i : 4 } , { y : 6 }, defer()
    await T.test_rpc c, "bar", { j : 2, k : 7 }, { y : 14}, defer()
    x.close()
    x = c = null
  cb ok

exports.destroy = (cb) ->
  await s.close defer()
  s = null
  cb()
