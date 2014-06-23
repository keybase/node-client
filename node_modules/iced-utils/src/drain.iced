
##
## A drain that you can hook up to a stream that will drain it all
## into a single buffer...
##

stream = require 'stream'

#=======================================================================================

# Drain the stream into a buffer.
exports.Drain = class Drain extends stream.Writable

  constructor : () ->
    @_bufs = []
    super

  _write : (data, encoding, cb) ->
    @_bufs.push data
    cb null

  data : () ->
    Buffer.concat @_bufs

#=======================================================================================

# Take a stream, and cb when it's fully drained.  Callback with the buffer of what was
# in the stream.
exports.drain = drain = (strm, cb) ->
  d = new Drain()
  strm.pipe(d)
  done = (err, data) ->
    if (tmp = cb)?
      cb = null
      tmp err, data
  d.on 'finish', ()    -> done null, d.data()
  d.on 'error' , (err) -> done err , null

#=======================================================================================

