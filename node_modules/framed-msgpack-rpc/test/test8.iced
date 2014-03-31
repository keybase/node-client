{server,Transport,Client} = require '../src/main'

## Do the same test as test1, a second time, must to make
## sure that we can rebind a second time...

PORT = 8881
PROT = "P.1"
s = null
CONST = 110

crypto = require 'crypto'
rj = require 'random-json'

##=======================================================================

class MyServer extends server.SimpleServer
  
  constructor : (d) ->
    super d
    @_x = CONST
    
  get_program_name : () -> PROT
  h_reflect : (arg, res) -> res.result arg
  h_get_x : (arg, res) ->
    o = x : @_x
    @_x++
    res.result o

##=======================================================================

cli = null
clix = null

##=======================================================================

exports.init = (cb, gto) ->
  s = new MyServer { port : PORT }
  await s.listen defer err
  if not err
    await gto.connect PORT, PROT, defer(err, x, c), {}
    if x
      clix = x
      cli = c
      
  cb err

##=======================================================================

exports.test1 = (T, cb) ->

  arg =
    x : "simple stuff here"
    v : [0..100]
      
  n = 4
  for i in [0...n]
    await T.test_rpc cli, "reflect", arg, arg, defer()
    await T.test_rpc cli, "get_x", arg, { x : CONST+i } , defer()

  cb()

##=======================================================================

exports.destroy = (cb) ->
  clix.close()
  await s.close defer()
  s = null
  cb()
