
stream = require 'stream'

exports.Tee = class Tee extends stream.Transform
  constructor : (options) ->
    super()
    @out = options.out
    @once 'end', =>
      await @out.end defer()
      @emit 'end'

  _transform : (chunk, encoding, cb) ->
    await @out.write chunk, encoding defer()
    @push chunk
    cb()

