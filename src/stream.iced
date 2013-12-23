stream = require 'stream'
log = require './log'

##=======================================================================

exports.NullInStream = class NullInStream extends stream.Readable
  _read : (sz) -> 
    @push null
    true

##=======================================================================

exports.NullOutStream = class NullOutStream extends stream.Writable
  _write : (dat) -> true

##=======================================================================

exports.BufferInStream = class BufferInStream extends stream.Readable

  constructor : (@buf, options) ->
    super options

  _read : (sz) ->
    push_me = null
    if @buf.length > 0
      n = Math.min(sz,@buf.length)
      push_me = @buf[0...n]
      @buf = @buf[n...]
    @push push_me
    true

##=======================================================================

exports.BufferOutStream = class BufferOutStream extends stream.Writable

  constructor : (options) ->
    @_v = []
    super options

  _write : (dat) -> 
    console.log "xx " + dat.toString()
    @_v.push dat
    true

  data : () -> Buffer.concat @_v

##=======================================================================

exports.FnOutStream = class FnOutStream extends stream.Writable
  constructor : (@fn, options) -> super options
  _write : (dat) -> @fn dat

##=======================================================================
