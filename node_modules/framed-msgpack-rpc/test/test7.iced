{server,Transport,Client} = require '../src/main'

## Do the same test as test1, a second time, must to make
## sure that we can rebind a second time...

PORT = 8881
s = null

crypto = require 'crypto'
rj = require 'random-json'

##=======================================================================

class P_v1 extends server.Handler
    
  h_buggy : (arg, res) ->
    res.result arg
    # Now, generate some random junk in the buffer, and then send it down
    # the pipe!
    @transport._raw_write new Buffer [3...10]
  h_good : (arg, res) ->
    res.result arg

##=======================================================================

cli = null
clix = null
T_global = null

##=======================================================================

exports.init = (cb, gto) ->

  T_global = gto
  
  s = new server.ContextualServer 
    port : PORT
    classes :
      "P.1" : P_v1
        
  await s.listen defer err
  if not err
    await gto.connect PORT, "P.1", defer(err, x, c), {}
    if x
      clix = x
      cli = c
      
  cb err

##=======================================================================

exports.reconnect_after_server_error = (T, cb) ->

  arg =
    x : "simple stuff here"
    v : [0..100]
      
  n = 4
  for i in [0...n]
    await T.test_rpc cli, "buggy", arg, arg, defer()
    await setTimeout defer(), 10

  cb()

##=======================================================================

exports.reconnect_after_client_error = (T, cb) ->
  arg =
    x : "simple stuff here"
    v : [0..100]
  n = 4
  for i in [0...n]
    await T.test_rpc cli, "good", arg, arg, defer()
    # Poop on ourselves...
    clix._raw_write new Buffer [3...10]
    
    await setTimeout defer(), 10

  cb()

##=======================================================================

exports.destroy = (cb) ->
  clix.close()
  await s.close defer()
  s = null
  cb()
