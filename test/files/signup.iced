
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

exports.push_key = (T,cb) ->
  await user.push_key defer err
  T.no_error err
  cb()

exports.prove_github = (T,cb) ->
  await user.prove_github defer err
  T.no_error err
  cb()

exports.prove_twitter = (T,cb) ->
  await user.prove_twitter defer err
  T.no_error err
  cb()

exports.revoke_key = (T,cb) ->
  await user.revoke_key defer err
  T.no_error err
  cb()

