{users} = require '../lib/user'
alice = users().lookup 'test_alice'
bob = users().lookup 'test_bob'
charlie = users().lookup 'test_charlie'

exports.cleanup = (T,cb) ->
  cb()

