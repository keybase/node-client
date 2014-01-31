{users} = require '../lib/user'
alice = users().lookup 'test_alice'
bob = users().lookup 'test_bob'
charlie = users().lookup 'test_charlie'

exports.unfollow = (T,cb) ->
  await bob.unfollow alice, defer err
  await alice.unfollow charlie, defer err
  await charlie.unfollow alice, defer err
  cb()

