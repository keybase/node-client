
u1 = null
u2 = null
{users,User} = require '../lib/user'

exports.signup_2 = (T,cb) ->
  u2 = User.generate()
  T.assert u2, "a user was generated"
  await u2.full_monty T, { twitter : false, github : false }, defer err
  T.no_error err
  cb()

exports.follow_1 = (T,cb) ->
  u1 = users().get(0)
  await u2.follow u1, {remote : true}, defer err
  T.no_error err
  cb()

exports.unfollow = (T,cb) ->
  await u2.unfollow u1, defer err
  T.no_error err
  cb()

exports.follow_2 = (T,cb) ->
  await u2.follow u1, {remote : false}, defer err
  T.no_error err
  cb()
