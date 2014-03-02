
{users,User} = require '../lib/user'
alice = users().lookup 'test_alice'
bob = users().lookup 'test_bob'

exports.id_0 = (T,cb) ->
  await bob.id alice, defer err
  T.no_error err
  cb()

exports.follow_0 = (T,cb) ->
  await bob.follow alice, {remote : true }, defer err
  T.no_error err
  cb()

exports.unfollow_1 = (T,cb) ->
  await bob.unfollow alice, defer err
  T.no_error err
  cb()

exports.follow_1 = (T,cb) ->
  await bob.follow alice, {remote : true }, defer err
  T.no_error err
  cb()

