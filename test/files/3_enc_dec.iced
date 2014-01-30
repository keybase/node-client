
{users} = require '../lib/user'

u0 = u1 = null

exports.init = (T,cb) ->
  u1 = users().get(1)
  u0 = users().get(0)
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

exports.u0_follow_u1 = (T,cb) ->
  await u0.follow u1, { remote : true }, defer err
  T.no_error err
  cb err

exports.u0_encrypt_for_u1 = (T,cb) ->
  args = [ "encrypt", u1.username , "--track-local" ]
  await u0.keybase { args , stdin : msg, quiet : true } , defer err, out
  T.no_error err
  T.assert out, "got back a PGP message"
  ctext = out
  console.log ctext.toString('utf8')
  cb()

exports.u1_decrypt_from_u0 = (T,cb) ->
  args = [ "decrypt" ]
  console.log "ciphertext" 
  console.log ctext.toString()
  await u1.keybase { args, stdin : ctext, quiet : true }, defer err, out
  T.no_error err
  console.log err
  console.log out?.toString()
  console.log ctext?.toString()
  T.equal out.toString('utf8'), (msg+"\n"), "Got back original message"
  cb()


