
u2 = null
{User} = require '../lib/user'

exports.signup_2 = (T,cb) ->
  u2 = User.generate()
  T.assert u2, "a user was generated"
  await u2.full_monty T, defer err
  T.no_error err
  cb()