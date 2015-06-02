
{User} = require '../lib/user'

alice = bob = charlie = null

exports.init = (T,cb) ->
  tmp = {}
  await User.load_many { names : ['alice', 'bob', 'charlie'], res : tmp }, defer err
  {alice,bob,charlie} = tmp
  cb err

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
  T.equal out.toString('utf8'), msg, "Got back original message"
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

exports.alice_encrypt_for_charlie_with_sig = (T,cb) ->
  args = [ "encrypt", "--batch", "--sign" ].concat [ charlie.username ]
  await alice.keybase { args, stdin : msg, quiet : true }, defer err, out
  T.no_error err
  T.assert out, "got back a PGP message"
  ctext = out
  cb()

exports.charlie_decrypt_from_alice_with_sig = (T,cb) ->
  args = [ "decrypt" , "--batch", "--signed" ].concat(alice.assertions())
  await charlie.keybase { args, stdin : ctext, quiet : true }, defer err, out
  T.no_error err
  T.equal out.toString('utf8'), msg, "Got back original message"
  cb()

exports.cleanup = (T,cb) ->
  await bob.unfollow alice, defer err
  await alice.unfollow charlie, defer err
  await charlie.unfollow alice, defer err
  cb()

