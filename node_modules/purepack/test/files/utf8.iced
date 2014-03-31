mpack = require 'msgpack'
purepack = require '../../lib/main'

compare = (T, obj, nm) -> 
  packed = purepack.pack obj
  mpacked = mpack.pack(obj)
  T.equal packed.toString('base64'), mpacked.toString('base64')
  unpacked = purepack.unpack packed
  T.equal obj, unpacked, nm

exports.random_binary = (T,cb)->
  compare T, (String.fromCharCode(i & 0xff) for i in [0...10000])
  cb()

