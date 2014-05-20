
{users} = require '../lib/user'

alice = bob = charlie = null

exports.init = (T,cb) ->
  bob     = users().lookup_or_gen 'bob'
  alice   = users().lookup_or_gen 'alice'
  charlie = users().lookup_or_gen 'charlie'
  cb()

ctext = null

exports.alice_sign_homedir = (T, cb) ->
  args = ["dir", "sign", alice.homedir]
  await alice.keybase {args, quiet: true}, defer err, out
  T.no_error err
  console.log out
  T.assert out, ''
  ctext = out
  cb()
