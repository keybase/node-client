
{users,User} = require '../lib/user'
alice = users().lookup 'test_alice'
bob = users().lookup 'test_bob'

exports.init = (T,cb) ->
  bob = users().lookup_or_gen 'bob'
  cb()

addresses = [
  "1R818scEUSQYyLPFLQB6V1HRPqmj5j7bs", # For Stephanie...
  "1HGMboMmV5VjaJ2NLa3Tj8o7b9EXBnw1fN" # for Dean Young...
]

exports.register_address_1 = (T,cb) ->
  args = [ "btc", addresses[0] ]
  await bob.keybase { args, quiet : true }, defer err, out
  T.no_error err
  T.assert out
  cb()  

exports.register_address_2 = (T,cb) ->
  args = [ "btc", addresses[0] ]
  await bob.keybase { args, quiet : true }, defer err, out
  T.assert err?, "expected an error for a second attempt to register the same"
  cb()  

exports.replace_address_1 = (T,cb) ->
  args = [ "btc", addresses[1] ]
  eng = bob.keybase_expect args
  await eng.conversation [
    { expect : (new RegExp "You already have registered address #{addresses[0]}; revoke and proceed\\? \\[y/N\\] ") }
    { sendline : "y"}
  ], defer err
  T.no_error err
  cb()

