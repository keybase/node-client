
{users} = require '../lib/user'

alice = bob = charlie = null

exports.init = (T,cb) ->
  bob = users().lookup 'test_bob'
  alice = users().lookup 'test_alice'
  charlie = users().lookup "test_charlie"
  cb()

msg = """
The golden smithies of the Emperor!
Marbles of the dancing floor
Break bitter furies of complexity,
Those images that yet
Fresh images beget,
That dolphin-torn, that gong-tormented sea.
"""

ctext = null

decrypt = (T,who,cb) ->
  args = [ "decrypt" ]
  await who.keybase { args, stdin : ctext, quiet : true }, defer err, out
  T.no_error err
  T.equal out.toString('utf8'), (msg+"\n"), "Got back original message"
  cb()

exports.alice_follow_bob = (T,cb) ->
  await alice.follow bob, { remote : true }, defer err
  T.no_error err
  cb err

exports.u0_encrypt_for_u1 = (T,cb) ->
  args = [ "encrypt", bob.username ]
  await alice.keybase { args , stdin : msg, quiet : true } , defer err, out
  T.no_error err
  T.assert out, "got back a PGP message"
  ctext = out
  cb()

exports.bob_decrypt_from_alice = (T,cb) ->
  await decrypt T, bob, defer()
  cb()

exports.alice_encrypt_for_charlie = (T,cb) ->
  args = [ "encrypt", "--batch" ].concat(charlie.assertions()).concat [ charlie.username ]
  await alice.keybase { args, stdin : msg, quiet : true }, defer err, out
  T.no_error err
  T.assert out, "got back a PGP message"
  ctext = out
  cb()

exports.charlie_decrypt_from_alice = (T,cb) ->
  await decrypt T, charlie, defer()
  cb()

