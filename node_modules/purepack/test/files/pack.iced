purepack = require '../../lib/main'

{tests} = require '../pack/data.js'

make_test = (k,v) -> (T, cb) ->
  try
    # We don't want str8 encodings yet because the main node msgpack
    # module doesn't output them.  So disable with this flag.
    mine = purepack.pack v.input, { no_str8 : true }

    T.equal mine.toString('base64'), v.output, "Compare to msgpack4 in #{k}"
    unpacked = purepack.unpack(mine)

    # undefined != null is OK for now...
    unless k is 'u1'
      T.equal unpacked, v.input, "Round trip failure in #{k}"
      
  catch e
    # Browserified buffers don't handle Gothic (extended UTF8) or
    # bad UTf8, so we'll just skip them for now...
    if (k in [ 'gothic', 'bad_utf1']) and e.toString().match(/URIError/) and window?
      # it's OK
    else
      T.error "unexpected error in #{k}: #{e}"

  cb()

for k,v of tests
  exports[k] = make_test k, v

