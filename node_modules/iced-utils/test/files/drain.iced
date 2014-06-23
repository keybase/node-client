
fs = require 'fs'
{drain} = require '../../lib/main'
{bufeq_secure} = require('../../lib/main').util

exports.test_drain_file = (T,cb) ->
  stream = fs.createReadStream process.argv[1]
  await drain.drain stream, defer err, dat
  T.no_error err
  await fs.readFile process.argv[1], defer err, dat2
  T.no_error err
  T.assert bufeq_secure dat, dat2
  cb()
