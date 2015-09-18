purepack = require '../../lib/main'


exports.sort1 = (T,cb) ->
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
  packed = purepack.pack obj, { sort_keys : true }
  unpacked = purepack.unpack packed
  T.assert unpacked?, "got an unpacked value back (with no Throw)"
  T.equal obj, unpacked, "sorting packs/unpacks"
  cb()

