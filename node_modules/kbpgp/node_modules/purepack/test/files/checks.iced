
purepack = require '../../lib/main'

exports.sort_check_1 = (T,cb) ->
  obj =
    cat : 1
    dog : 2
    apple : 3
    tree : 4
    bogey : 5
    zebra : 6
    echo : 7
    yankee : 8
    golf : 9
  packed = purepack.pack obj, { sort_keys : false }
  err = null
  try
    purepack.unpack packed, { strict : true }
  catch e
    err = e
  T.assert err?, "threw an error on lack of sorting"
  packed = purepack.pack obj, { sort_keys : true }
  res = purepack.unpack packed, { strict : true }
  T.assert res?, "sorted check passed"
  cb()

exports.strict_check_duplicate_keys_1 = (T,cb) ->
  key = purepack.pack "key"
  v1 = purepack.pack 1
  v2 = purepack.pack 2
  dict = Buffer.concat [
    new Buffer([ 0x82 ] ), # fixed map with 2 elements
    key  # "key"
    v1   # 1
    key  # "key"
    v2   # 2
  ]
  res = err = null
  try
    res = purepack.unpack dict, { strict : false }
  catch e
    err = e
  T.assert err?, "multiple keys fail even in strict mode"
  T.equal err.message, "duplicate key 'key'"
  cb()


exports.strict_check_understuffed = (T,cb) ->


  understuffs = [

    # Maps
    {
      buf : Buffer.concat([
        new Buffer([0xde, 0x00, 0x01 ]), # A 16-bit-sized buffer, with just 1 item
        purepack.pack("key"),
        purepack.pack(2)
      ]),
      wanted : 6, got : 8,
      name : "want fix map, got map16"
    },
    {
      buf : Buffer.concat([
        new Buffer([0xdf, 0x00, 0x00, 0x00, 0x01 ]), # A 16-bit-sized buffer, with just 1 item
        purepack.pack("key"),
        purepack.pack(2)
      ]),
      wanted : 6, got : 10,
      name : "want fix map, got map32"
    },

    # arrays
    {
      buf : new Buffer([0xdc, 0x00, 0x01, 0x2 ]) # A 16-bit-sized buffer, with just 1 item (the number 2)
      wanted : 2, got : 4,
      name : "want fix array, got array16"
    },
    {
      buf : new Buffer([0xdd, 0x00, 0x00, 0x00, 0x01, 0x02 ]) # A 16-bit-sized buffer, with just 1 item
      wanted : 2, got : 6,
      name : "want fix array, got array32"
    },

    # strings
    {
      buf : new Buffer([0xd9, 0x04, 0x61, 0x62, 0x63, 0x64 ]), # the 8-bit fixed case
      wanted : 5, got : 6,
      name : "want fix str, got str8"
    },
    {
      buf : new Buffer([0xda, 0x0, 0x04, 0x61, 0x62, 0x63, 0x64 ]), # the 16-bit fixed case
      wanted : 5, got : 7,
      name : "want fix str, got str16"
    },
    {
      buf : new Buffer([0xdb, 0x0, 0x0, 0x0, 0x04, 0x61, 0x62, 0x63, 0x64 ]), # the 32-bit fixed case
      wanted : 5, got : 9,
      name : "want fix str, got str32"
    }

    # uints
    {
      buf : new Buffer([0xcc, 0x0d ]), # the 8-bit fixed case
      wanted : 1, got : 2,
      name : "want fix int, got uint8"
    },
    {
      buf : new Buffer([ 0xcd, 0x00, 0x0d ]), # the 16-bit fixed case
      wanted : 1, got : 3,
      name : "want fix int, got uint16"
    },
    {
      buf : new Buffer([ 0xce, 0x00, 0x00, 0x00, 0x0d ]), # the 32-bit fixed case
      wanted : 1, got : 5,
      name : "want fix int, got uint32"
    },
    {
      buf : new Buffer([ 0xce, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0d ]), # the 64-bit fixed case
      wanted : 1, got : 9,
      name : "want fix int, got uint64"
    },

    # binary
    {
      buf : new Buffer([0xc5, 0x00, 0x04, 0xff, 0xfe, 0x50, 0x55 ]),
      wanted : 6, got : 7,
      name : "want bin8, got bin16"
    },
    {
      buf : new Buffer([0xc6, 0x00, 0x00, 0x00, 0x04, 0xff, 0xfe, 0x50, 0x55 ]),
      wanted : 6, got : 9,
      name : "want bin8, got bin32"
    },

    # ints
    {
      buf : new Buffer([0xd0, 0xf0 ]), # the 8-bit fixed case
      wanted : 1, got : 2,
      name : "want fix int, got int8"
    },
    {
      buf : new Buffer([ 0xd1, 0xff, 0xf0 ]), # the 16-bit fixed case
      wanted : 1, got : 3,
      name : "want fix int, got int16"
    },
    {
      buf : new Buffer([ 0xd2, 0xff, 0xff, 0xff, 0xf0 ]), # the 32-bit fixed case
      wanted : 1, got : 5,
      name : "want fix int, got int32"
    },
    {
      buf : new Buffer([ 0xd3, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xf0 ]), # the 64-bit fixed case
      wanted : 1, got : 9,
      name : "want fix int, got int64"
    },

    # binary


  ]

  for {buf,wanted,got,name},i in understuffs
    err = null
    try
      res = purepack.unpack buf, { strict : true }
    catch e
      err = e
    T.assert err?, "understuffed failure in strict mode (#{name} / #{i})"
    T.equal err.message, "encoding size mismatch: wanted #{wanted} but got #{got}"
    T.waypoint name
  cb()

