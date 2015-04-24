
keyring = require '../../lib/keyring'

#-----------------------------------

class Log extends keyring.Log
  debug : (x) -> 

#-----------------------------------

ring2 = ring = null
key = null
key_data = """
  -----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.14 (GNU/Linux)

mI0EUqpp2QEEANFByr3uPGsG5DqmV3kPLsTEmew5d8NcD3SqASas342LB5sDE0D6
0fTDvjLYAiCTgVlZrSIx+SeeskygKH/AwnTCBK04V0HgpR0tyw+dGIV5ujFIo236
O8XvIqaVoR1/zizy8fOSaFqr8rPQf3JYWxQn8IMLUS+ricOUZS/YSgNVABEBAAG0
M0dhdmlyaWxvIFByaW5jaXAgKHB3IGlzICdhJykgPGdtYW5AdGhlYmxhY2toYW5k
LmlvPoi+BBMBAgAoBQJSqmnZAhsDBQkSzAMABgsJCAcDAgYVCAIJCgsEFgIDAQIe
AQIXgAAKCRDuXBLqbhXbknHWBACGwlrWuJyAznzZ++EGpvhVZBdgcGlU3CK2YOHC
M9ijVndeXjAtAgUgW1RPjRCopjmi5QKm+YN1WcAdf6I+mnr/tdYhPYnRE+dNsEB7
AWGsiwZOxQbwtCOIR+5AU7pzIoIUW1GsqQK3TbiuSRYI5XG6UdcV5SzQI96aKGvk
S6O6uLiNBFKqadkBBADW31A7htB6sJ71zwel5yyX8NT5fD7t9xH/XA2dwyJFOKzj
R+h5q1KueTPUzrV781tQW+RbHOsFEG99gm3KxuyxFkenXb1sXLMFdAzLvBuHqAjQ
X9pJiMTCAK7ol6Ddtb/4cOg8c6UI/go4DU+/Aja2uYxuqOWzwrantCaIamVEywAR
AQABiKUEGAECAA8FAlKqadkCGwwFCRLMAwAACgkQ7lwS6m4V25IQqAQAg4X+exq1
+wJ3brILP8Izi74sBmA0QNnUWk1KdVA92k/k7qA/WNNobSZvW502CNHz/3SQRFKU
nUCByGMaH0uhI6Fr1J+pjDgP3ZelZg0Kw1kWvkvn+X6aushU3NHtyZbybjcBYV/t
6m5rzEEXCUsYrFvtAjG1/bMDLT0t1AA25jc=
=59sB
-----END PGP PUBLIC KEY BLOCK-----
"""
fingerprint = "1D1A20E57C763DD42258FBC5EE5C12EA6E15DB92"

payload = "I hereby approve of the Archduke's assassination.  Please spare his wife.\n"
sig = """
-----BEGIN PGP MESSAGE-----
Version: GnuPG v1.4.14 (GNU/Linux)

owGbwMvMwMT4LkboVZ7o7UmMpwOSGIJu/27zVMhILUpNqlRILCgoyi9LVchPUyjJ
SFVwLErOSCnNTlUvVkgsLgaizLzEksz8PD0FhYCc1MTiVIXigsSiVIWMzGKF8sy0
VD2ujjksDIxMDGysTCBzGbg4BWCWrVNjYWg1Py9w8X/oMuuysk7JcilXkWqjy9uX
N8bOfbp+ZZK7rYGMD++edRt9Mk5ITp+2cPcunVXv2FmCO6d6SD3lnOybvcXytJFt
S+fz1cqTPdi3dT47XXj97IWY65u1pO9HBUZmy0/YzihX4Pz/ZIO7hnfb1N4l7Fw/
Hz30FTkcaHWq7oPoHAWeYwA=
=2ENa
-----END PGP MESSAGE-----
"""

#-----------------

kaiser2 =
  key_data : """
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

mQENBFLf0DYBCADGz/jWmSDY8c4yVorLgDXK1GpHmqmGOaacBjdSC0Os0+oBcvI7
o7rVZkkOeHoLGfr4HaQ6iXF61PxMjRpvUmDMrznrYGnOsSiiY0S6IFmAoEnu7BqI
2ZPQEwqxV4o9iQ6ttffh0LC/5IX3+0sXt6uWebAyE0fW3Rw1drSaElUdzXRu7/nw
e75oLhNSVguLFMhhs6VvUglcYRsZJN+hNOW0oVOIBWHDCtI713U/wFepaOov0g48
Ysj2gFLnhUMGPgb+yTKeDLvlQQCZoIXBWWTy7sM/LU0xsegP0Wpsv+aj7fNcoxYp
tuqQwPOzu35B7J4++ECmQ0qoVND9j5iChA2xABEBAAG0IkthaXNlciBXaWxoZWxt
IDxrYWlzZXIyQHlhaG9vLmNvbT6JAT0EEwEKACcFAlLf0DYCGwMFCRLMAwAFCwkI
BwMFFQoJCAsFFgIDAQACHgECF4AACgkQY+EQEyiPLUiCcQf/REXdwDfJRHc7DpWJ
M/o+NDke4d60gh3wtNRUWlsbAF/Xc1aZjEJt0xRIx3QJ8P5+FYfMsk2/05UfXmrg
KE69AEP2x3FcbnkYeSG0jwbDi5h7such17SDxV9M/s4iHjJKBglyDxYltG2xZ8Xu
NNTi2VkvvulrRcwonQr/hPDibMKIgY7Xrxw3nZK/pOOXaidcIvuoGpOd9w3UniGc
zOzSi3CqTQrpf+5/p0rZE2tdJdNTm2MUww8FiUzpzdUfMAunVSpK1WazpWXkJ9sS
4H6dE+GUWh71f4j69NNfzOG4YWQ6syjJ12BtlLRNl403LvPubhVaKr0gHF5wEeI0
4h0YR7kBDQRS39A2AQgA6Vfl/9NBltJOxQ921rJJTqsjxW/chIX1HGYEYWRrJrfD
iEoC1jYDOKmP6q6PYREeyhB1G5uER2FQnjtxY8Wo+BpwsJ+s/stgRZoHUM2AsmPb
rnEt8J781trSjbTuySgRkqsQAQizhrsAq0jnpOCmAPVbsFvC4oV9kjiXDOet2j9j
tfZ5FnfESqQ0tmrdIXvKaa3+jE5hnRvyhBrwyoYny6SBw4eqogUjQnUa1yo4X0Si
dPmNDA6DdIFG6+OxR3emRNxeuYRq3oHJLAalGlhMQCn8QK1RyoyRqDcekMHB0hYV
uNgxgta11hIdipBohrJIeKVcGKXt29XSnS0iWdm/DQARAQABiQElBBgBCgAPBQJS
39A2AhsMBQkSzAMAAAoJEGPhEBMojy1I1t8H/3hXg/3WwN33iY1bodU8oXYVBbKG
pjs/A/fP/H3+3MqG6z/sspUfXluS7baNRmg5HB300vMGqPRJ5EU5/anOu/EJxj1A
NJpSiJnXyjwVx7EviMgLPlZC0HTYNPsiXZLe7p/WAWHy5HRH9iAgu0IOPon1MniV
9lgJHsOS+zF+ostVB6PFglEJt4y7ySeFuxpRTi0ulYyO/LHW7nJZkl6xzpvykJws
3it8W3ecYAodkySzgLN8zqS8nlqlsJgO/NYIQd3c67MKA+92A75VlCMJ25SrsaVm
Enqh2naqYfmkmhWk5KInf02pSAwD5I/roTYO9kO1QjLrVj1d058K2/T2Z0o=
=U857
-----END PGP PUBLIC KEY BLOCK-----
"""
  username : "kaiser2@yahoo.com"
  fingerprint : "A03CC843D8425771B59F731063E11013288F2D48"
  payload_json : { ww : 1 }
  payload : '{ "ww" : 1 }\n'
  sig : """-----BEGIN PGP MESSAGE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

owEBQwG8/pANAwAKAWPhEBMojy1IAcsTYgBS39KUeyAid3ciIDogMSB9CokBHAQA
AQoABgUCUt/SlAAKCRBj4RATKI8tSN+tB/90cxDDxC0PjoPqbO2ZrbI1q2FGyZI3
Ayukt+u/cTadECcigJzE05ymKevKCVJFHASEp4SMn9nW4QSD5fTRcqo6QBfWImQi
UYbirBvhejAARusJmLKtpmosxxsiEYQ1bcFJjx2+UQLr40uw5RHXfgP8CuUqadrw
Wm+wqLwUwXxbrYb5FCZ8nziEUwOl2rpqV1NIj59D3BZps43Q5QCCTRZF5+eJJyg+
AhyYGythrOMbYKWmRRGhIdy3QU34IHGxNh3o2bz6YBiM/JD8CY0M0HT33xU93LvB
7UowhdY7p9M8R0Ql21T4+5AOxPxHQIypRKOl5oJPvZg8avtDT8sc5fRw
=Uy2n
-----END PGP MESSAGE-----
"""

#-----------------

exports.init = (T, cb) ->
  keyring.init {
    get_preserve_tmp_keyring : () -> false
    get_tmp_keyring_dir : () -> "."
    log : new Log()
  }
  cb()

#-----------------

exports.make_ring = (T,cb) ->
  await keyring.TmpKeyRing.make defer err, tmp
  T.no_error err
  T.assert tmp, "keyring came back"
  ring = tmp
  cb()

#-----------------

exports.test_import = (T,cb) ->
  key = ring.make_key {
    key_data,
    fingerprint,
    username : "gavrilo"
  }
  await key.save defer err
  T.no_error err
  await key.load defer err
  T.no_error err
  cb()

#-----------------

exports.test_verify = (T,cb) ->
  await key.verify_sig { sig, payload, which : "msg" }, defer err
  T.no_error err
  cb()

#-----------------

exports.test_read_uids = (T, cb) ->
  await ring.read_uids_from_key { fingerprint }, defer err, uids
  T.no_error err
  T.equal uids.length, 1, "the right number of UIDs"
  # Whoops, there was as typo when I made this key!
  T.equal uids[0].username, "Gavirilo Princip" , "the right username"
  cb()

#-----------------

exports.test_copy = (T,cb) ->
  await keyring.TmpKeyRing.make defer err, ring2
  T.no_error err
  T.assert ring2, "keyring2 was made"
  await ring2.read_uids_from_key { fingerprint }, defer err, uids
  T.assert err, "ring2 should be empty"
  key2 = key.copy_to_keyring ring2
  await key2.save defer err
  T.no_error err
  await key2.load defer err
  T.no_error
  await key2.verify_sig { sig, payload, which : "key2" }, defer err
  T.no_error err
  await ring2.nuke defer err
  T.no_error err
  cb()

#-----------------

exports.test_find = (T, cb) ->
  await ring.find_keys { query : "gman@" }, defer err, id64s
  T.no_error err
  T.equal id64s, [ fingerprint[-16...] ], "got back the 1 and only right key"
  cb()

#-----------------

exports.test_list = (T,cb) ->
  await ring.list_keys defer err, id64s
  T.no_error err
  T.equal id64s, [ fingerprint[-16...] ], "got back the 1 and only right key"
  cb()

#-----------------

exports.test_one_shot = (T,cb) ->
  await ring.make_oneshot_ring { query : fingerprint, single : true }, defer err, r1
  T.no_error err
  T.assert r1, "A ring came back"
  await r1.nuke defer err
  T.no_error err
  cb()

#-----------------

exports.test_oneshot_verify = (T,cb) ->
  key = ring.make_key kaiser2
  await key.save defer err
  T.no_error err
  await ring.oneshot_verify { query : kaiser2.username, single : true, sig : kaiser2.sig }, defer err, json
  T.no_error err
  T.equal kaiser2.payload_json, json, "JSON payload checked out"
  cb()  

#-----------------

exports.test_verify_sig = (T,cb) ->
  await key.verify_sig { which : "something", payload : kaiser2.payload, sig : kaiser2.sig }, defer err
  T.no_error err
  cb()

#-----------------

exports.test_import_by_username = (T,cb) ->
  key = ring.make_key {username : "<gman@theblackhand.io>"}
  await key.load defer err
  T.no_error err
  T.equal key.uid().username, 'Gavirilo Princip', "username came back correctly after load"
  cb()

#-----------------

exports.test_import_by_username_with_space_and_control_chars = (T,cb) ->
  if process.platform is 'win32'
    T.waypoint "skipped on windows :("
  else
    key = ring.make_key keybase_v1_index
    await key.save defer err
    T.no_error err
    key = ring.make_key {username : "(v1) <index@keybase.io>"}
    await key.load defer err
    T.no_error err
    T.equal key.uid().username, 'Keybase.io Index Signing', "username came back correctly after load"
  cb()

#-----------------

keybase_v1_index = 
  key_data : """
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - http://gpgtools.org

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
=kK8c
-----END PGP PUBLIC KEY BLOCK-----
"""

#-----------------

exports.nuke_ring = (T,cb) ->
  await ring.nuke defer err
  T.no_error err
  cb()

#==================================================================

keyring_raw = """
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - http://gpgtools.org

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
A+k/SlaiV1ZqK5YbGFS+
=7jBz
-----END PGP PUBLIC KEY BLOCK-----
"""

exports.index_keyring = (T,cb) ->
  await keyring.TmpKeyRing.make defer err, ring
  T.no_error err, "make tmp key ring"
  await ring.gpg { args : [ "--no-options", "--import"], stdin : keyring_raw, quiet : true }, defer err
  T.no_error err, "import worked ok"
  await ring.index defer err, index
  fp = "E0600318C622F735D82EDF3D5B094948B11151F2".toLowerCase()
  keys = index.lookup().fingerprint.get(fp)
  T.assert keys?, "key came back for our fingerprint #{fp}"
  T.equal keys.length, 1, "only one key came back" 
  T.equal keys[0].userids().length, 1, "only 1 userid"
  T.equal keys[0].userids()[0].username, "keybase.io/capndesign", "and it was the capn"
  T.no_error err, "indexing worked ok"
  await ring.nuke defer err
  T.no_error err, "nuked the ring ok"
  cb()

#======================================================================


