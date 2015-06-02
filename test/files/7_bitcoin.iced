
{User} = require '../lib/user'
alice = bob = null

exports.init = (T,cb) ->
  tmp = {}
  await User.load_many { names : ['alice', 'bob' ], res : tmp }, defer err
  {alice,bob} = tmp
  cb err

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

sig_id = null

exports.lookup_sig_id_1 = (T,cb) ->
  args = [ "list-sigs", "-j", "-t", "currency" ]
  await bob.keybase { args, quiet : false }, defer err, out
  T.no_error err
  o = JSON.parse out.toString()
  last = o[-1...][0]
  sig_id = last.id
  T.assert sig_id?, "got back a sig_id"
  T.equal last.type, 'currency', 'of the right form'
  T.assert last.live, 'it is now live'
  cb()

exports.revoke_sig_1 = (T,cb) ->
  args = [ "revoke-sig", sig_id ]
  await bob.keybase { args, quiet : true}, defer err, out
  T.no_error err
  cb()
