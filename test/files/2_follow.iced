
{User} = require '../lib/user'
users = {}

exports.init = (T,cb) ->
  await User.load_many { names : ['alice', 'bob'], res : users }, defer err
  cb err

exports.id_0 = (T,cb) ->
  await users.bob.id users.alice, defer err
  T.no_error err
  cb()

exports.follow_0 = (T,cb) ->
  await users.bob.follow users.alice, {remote : true }, defer err
  T.no_error err
  cb()

exports.unfollow_1 = (T,cb) ->
  await users.bob.unfollow users.alice, defer err
  T.no_error err
  cb()

exports.follow_1 = (T,cb) ->
  await users.bob.follow users.alice, {remote : true }, defer err
  T.no_error err
  cb()

