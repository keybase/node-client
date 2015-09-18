purepack = require '../../lib/main'
{tests} = require '../pack/data.js'

eq = (T,a,b,s) ->
  if a? or b? then T.equal(a,b,s)

random_n = (n) -> Math.floor(Math.random() * n)

randobuf = () ->
  len = random_n(100)
  arr = new Uint8Array(random_n(256) for [0...len] )
  new Buffer arr

bufeq = (T, a, b, m) ->
  T.equal a.length, b.length, "#{m} length"
  for i in [0...a.length]
    T.equal a.readUInt8(i), b.readUInt8(i), "#{m} @ #{i}"

make_test = (k,v) -> (T,cb) ->
  framed = purepack.frame.pack v.input, {}
  [ret, rem] = purepack.frame.unpack framed
  eq T, v.input, ret, "round trip worked"
  T.equal rem.length, 0, "no remaining frogs"
  r = randobuf()
  framed = Buffer.concat [ framed, r ]
  [ret, rem] = purepack.frame.unpack framed
  eq T, v.input, ret, "round trip worked"
  bufeq T, rem, r, "random was right"
  cb()

#=========================================================================

for k,v of tests when not v.difficult
  exports[k] = make_test k, v

#=========================================================================

exports.test_bad_frames = (T,cb) ->
  obj = { a : "dog", b : [0...1000] }
  framed = purepack.frame.pack obj, {}
  for i in [0...200]
    try
      [ret,rem] = purepack.frame.unpack framed[0...i]
      T.assert false, "trunc at byte #{i}" 
    catch error
      # good!
  cb()
  
#=========================================================================

