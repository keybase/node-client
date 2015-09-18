purepack = require '../../lib/main'

compare = (T, obj, nm) ->
  packed = purepack.pack obj
  unpacked = purepack.unpack packed
  T.equal obj, unpacked, nm

exports.unpack1 = (T, cb) ->
  compare T, "hello", "unpack1"
  cb()

exports.unpack2 = (T, cb) ->
  compare T, { hi : "mom", bye : "dad" }, "unpack2"
  cb()

exports.unpack3 = (T, cb) ->
  compare T, -100, "unpack3 test 0"
  compare T, -32800, "unpack3 test 0b"
  compare T, [-100..100], "unpack3 test 1"
  compare T, [-1000..1000], "unpack3 test 2"
  compare T, [-1000..1000], "unpack3 test 2"
  compare T, [-32800...-32700], "unpack3 test 4"
  compare T, [-2147483668...-2147483628], "unpack3 test 5"
  compare T, [0xfff0...0x1000f], "unpack3 test 6"
  compare T, [0xfffffff0...0x10000000f], "unpack3 test 7"
  compare T, -2147483649, "unpack 3 test 8"
  cb()

exports.unpack4 = (T, cb) ->
  compare T, [ 1.1, 10.1, 20.333, 44.44444, 5.555555], "various floats"
  compare T, [ -1.1, -10.1, -20.333, -44.44444, -5.555555], "various neg floats"
  cb()

exports.unpack5 = (T, cb) ->

  obj =
    foo : [0..10]
    bar :
      bizzle : null
      jam : true
      jim : false
      jupiter : "abc ABC 123"
      saturn : 6
    bam :
      boom :
        yam :
          potato : [10..20]
  compare T, obj, "unpack5"
  cb()

exports.unpack6 = (T,cb) ->
  obj = (i for i in [1...100]).join ' '
  compare T, obj, "unpack6a"
  d = { obj }
  compare T, obj, "unpack6b"
  cb()

exports.unpack7 = (T,cb) ->
  obj = (i for i in [1...23000]).join ' '
  compare T, obj, "unpack7a"
  d = { obj }
  compare T, obj, "unpack7b"
  cb()

exports.unpack8 = (T,cb) ->
  obj = (String.fromCharCode(i&0x7f) for i in [1...23000]).join ''
  compare T, obj, "unpack8a"
  d = { obj }
  compare T, obj, "unpack8b"
  cb()

exports.unpack9 = (T,cb)->
  obj =
    email : "themax@gmail.com"
    notes : "not active yet, still using old medium security. update this note when fixed."
    algo_version : 3,
    length : 12
    num_symbols : 0
    generation : 1
    security_bits : 8
  compare T, obj, "unpack9"
  cb()

exports.corrupt1 = (T,cb) ->
  x = new Buffer (new Uint8Array [135, 165, 101, 109, 97, 105, 108, 176, 116, 104, 101, 109, 97,
                      120, 64, 103, 109, 97, 105, 108, 46, 99, 111, 109, 165, 110, 111,
                      116, 101, 115, 219, 0, 77, 110, 111, 116, 32, 97, 99, 116, 105, 118,
                      101, 32, 121, 101, 116, 44, 32, 115, 116, 105, 108, 108, 32, 117, 115,
                      105, 110, 103, 32, 111, 108, 100, 32, 109, 101, 100, 105, 117, 109,
                      32, 115, 101, 99, 117, 114, 105, 116, 121, 46, 32, 117, 112, 100, 97,
                      116, 101, 32, 116, 104, 105, 115, 32, 110, 111, 116, 101, 32, 119, 104,
                      101, 110, 32, 102, 105, 120, 101, 100, 46, 172, 97, 108, 103, 111, 95,
                      118, 101, 114, 115, 105, 111, 110, 3, 166, 108, 101, 110, 103, 116, 104,
                      12, 173, 115, 101, 99, 117, 114, 105, 116, 121, 95, 98, 105, 116, 115, 8,
                      171, 110, 117, 109, 95, 115, 121, 109, 98, 111, 108, 115, 0, 170, 103, 101,
                      110, 101, 114, 97, 116, 105, 111, 110, 1])
  res = err = null
  try
    res = purepack.unpack x, 'ui8a'
  catch e
    err = e
  T.assert err?, "error was found"
  m = err.toString()
  if m?
    T.equal m, "Error: Corruption: asked for 5074543 bytes, but only 137 available"
  else
    T.error "Failed to get expected text in Error message"
  cb()

exports.floats = (T,cb) ->
  obj = [ 1.2222, -10.10, 200.200, -3333.333, -5000000, 50000000 ]
  packed = purepack.pack obj, { floats : true }
  unpacked = purepack.unpack packed
  T.assert( (not err?), "packing of floats worked..." )
  for val,i in obj
    T.assert((Math.abs(val - unpacked[i]) < .0001), "float-#{i} (#{val})")
  cb()

exports.corrupt2 = (T,cb) ->
  bufs = [
    (new Buffer "863921940343f3ddbde3bf7c00d0faeb9e7aeb9e", "hex")
    (new Buffer "jhljhlkjhjkhl) AND 8929=4798 AND (6655=6655", "base64")
  ]
  for b,i in bufs
    err = null
    try
      p = purepack.unpack b
    catch e
      err = e
    T.assert err?, "we got an error for reading off the array (attempt #{i})"
  cb()


