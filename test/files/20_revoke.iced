
{User} = require '../lib/user'
bob = null
log = require '../../lib/log'

user = null

exports.signup = (T,cb) ->
  user = User.generate()
  T.assert user, "user was generated"
  await user.full_monty T, { twitter : true, github : false }, defer err
  T.no_error err
  cb()

exports.cleanup = (T,cb) ->
  await user.cleanup defer err
  T.no_error err
  cb()
