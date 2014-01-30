{users} = require '../lib/user'
alice = users().lookup 'test_alice'
bob = users().lookup 'test_bob'

exports.unfollow = (T,cb) ->
  await bob.unfollow alice, defer err
  cb()

