
{User} = require '../lib/user'
bob = null
log = require '../../lib/log'

exports.signup = (T,cb) ->
  user = User.generate()
  T.assert user, "user was generated"
  await user.full_monty T, { twitter : false, github : false }, defer err
  T.no_error err
  await user.revoke_key defer err
  T.no_error err
  cb()
