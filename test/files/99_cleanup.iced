
{users} = require '../lib/user'

exports.clean = (T,cb) ->
  await users().cleanup defer err
  T.no_error err
  cb()
