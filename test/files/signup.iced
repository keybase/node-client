
{User} = require '../lib/user'
user = null

exports.generate = (T,cb) ->
  user = User.generate()
  T.assert user, "a user came back"
  cb()

exports.init_user = (T,cb) ->
  await user.init defer err
  T.no_error err
  cb()

exports.signup = (T,cb) ->
  await user.signup defer err
  T.no_error err
  cb()
