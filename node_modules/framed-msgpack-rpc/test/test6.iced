{server,Transport,Client} = require '../src/main'

## Do the same test as test1, a second time, must to make
## sure that we can rebind a second time...

PORT = 8881
s = null

crypto = require 'crypto'
rj = require 'random-json'

SLOW = 500

##=======================================================================

class P_v1 extends server.Handler
  h_reflect : (arg, res) ->
    await setTimeout defer(), SLOW
    res.result arg

##=======================================================================

exports.init = (cb) ->
  
  s = new server.ContextualServer 
    port : PORT
    classes :
      "P.1" : P_v1
        
  await s.listen defer err
  cb err

##=======================================================================

exports.slow_warnings = (T, cb) ->

  rtops =
    warn_threshhold : SLOW / 4000
    error_threshhold : SLOW / 2000

  await T.connect PORT, "P.1", defer(x, c), rtops
  
  if x

    arg =
      x : "simple stuff here"
      v : [0..100]
      
    n = 4
    for i in [0...n]
      await T.test_rpc c, "reflect", arg, arg, defer()

    x.close()

  cb()

##=======================================================================

exports.destroy = (cb) ->
  await s.close defer()
  s = null
  cb()
