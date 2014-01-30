
u0 = null
u1 = null
{users,User} = require '../lib/user'

exports.signup_2 = (T,cb) ->
  u1 = User.generate()
  T.assert u1, "a user was generated"
  await u1.full_monty T, { twitter : false, github : false }, defer err
  T.no_error err
  cb()

exports.follow_1 = (T,cb) ->
  u0 = users().get(0)
  await u1.follow u0, {remote : true}, defer err
  T.no_error err
  cb()

exports.unfollow = (T,cb) ->
  await u1.unfollow u0, defer err
  T.no_error err
  cb()

exports.follow_2 = (T,cb) ->
  await u1.follow u0, {remote : false}, defer err
  T.no_error err
  cb()
