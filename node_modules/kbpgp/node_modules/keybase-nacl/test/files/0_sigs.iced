
main = require '../../'
{rng} = require 'crypto'

tweak = (x, pos) ->
  pos or= 0
  x[pos] ^= 0x1

msg = new Buffer """The vision of a rock where lightnings whirl'd
  Bruising the darkness with their carkling light ;""", "utf8"

test = (T,detached,signer,verifier,cb) ->
  sig = signer.sign { payload: msg, detached }
  [err, payload] = verifier.verify { payload : msg, detached, sig }
  T.no_error err
  tweak msg
  [err, payload] = verifier.verify { payload : msg, detached, sig }
  T.assert err?, "bad payload"
  T.assert not payload?, "no payload came back"
  tweak msg
  tweak signer.publicKey
  [err, payload] = verifier.verify { payload : msg, detached, sig }
  T.assert err?, "bad key"
  T.assert not payload?, "no payload came back"
  tweak signer.publicKey
  tweak sig
  [err, payload] = verifier.verify { payload : msg, detached, sig }
  T.assert err?, "bad sig"
  T.assert not payload?, "no payload came back"
  if not detached?
    tweak sig
    tweak sig, main.sign.signatureLength + 3
    [err, payload] = verifier.verify { payload : msg, detached, sig }
    T.assert err?, "bad sig"
    T.assert not payload?, "no payload came back"
  cb()

test_both = (T,sign,verify,cb) ->
  await test T, true, sign, verify, defer()
  await test T, false, sign, verify, defer()
  cb()

exports.test_sodium_sodium = (T, cb) ->
  sodium = main.alloc { force_js : false }
  sodium.genFromSeed { seed : rng(main.sign.seedLength) }
  await test_both T, sodium, sodium, defer err
  cb err

exports.test_sodium_tweetnacl = (T, cb) ->
  sodium = main.alloc { force_js : false }
  sodium.genFromSeed { seed : rng(main.sign.seedLength) }
  tweetnacl = main.alloc { force_js : true, publicKey : sodium.publicKey, secretKey : sodium.secretKey }
  await test_both T, sodium, tweetnacl, defer err
  cb err

exports.test_tweetnacl_tweetnacl = (T, cb) ->
  tweetnacl = main.alloc { force_js : true }
  tweetnacl.genFromSeed { seed : rng(main.sign.seedLength) }
  await test_both T, tweetnacl, tweetnacl, defer err
  cb err

exports.test_tweetnacl_sodium = (T, cb) ->
  sodium = main.alloc { force_js : false }
  sodium.genFromSeed { seed : rng(main.sign.seedLength) }
  tweetnacl = main.alloc { force_js : true, publicKey : sodium.publicKey, secretKey : sodium.secretKey }
  await test_both T, tweetnacl, sodium, defer err
  cb err

