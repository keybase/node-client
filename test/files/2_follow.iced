
{users,User} = require '../lib/user'
alice = users().lookup 'test_alice'
bob = users().lookup 'test_bob'

exports.unfollow_0 = (T,cb) ->
  await bob.unfollow alice, defer err
  T.no_error err
  cb()

exports.follow_1 = (T,cb) ->
  await bob.follow alice, {remote : true }, defer err
  T.no_error err
  cb()

exports.unfollow_1 = (T,cb) ->
  await bob.unfollow alice, defer err
  T.no_error err
  cb()

exports.follow_2 = (T,cb) ->
  await bob.follow alice, {remote : false}, defer err
  T.no_error err
  cb()

exports.follow_3 = (T,cb) ->
  await bob.follow alice, {remote : true}, defer err
  T.no_error err
  cb()
