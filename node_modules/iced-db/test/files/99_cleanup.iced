
{db} = require './lib'

#=================================

exports.cleanup = cleanup = (T,cb) ->
  await db.drop defer err
  T.no_error err
  cb()

#=================================
