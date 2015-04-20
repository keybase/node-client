
{parse} = require '../../lib/main'

exports.test_parse = (T,cb) ->
  message = """
-----BEGIN PGP MESSAGE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

owEBPALD/ZANAwAKAS/gHEVDSNo5AcsMYgBSzEhJaGVsbG8KiQIcBAABCgAGBQJS
zEhJAAoJEC/gHEVDSNo5d5gQAMHe2bPIFLL8wdu+KG9rkSqZ3iHloaHTkhN729T1
+OefN1YeS7RpOHMcptNKtu36f9LFeDUCfgeevXcL3v3f5Crvl1TCmAft87HlsqZ0
2L++qULRkauu2+HYHB0tr5RwaTYH8A3rYLD79Atrh0XStHcsh3C6ISmePEl+eStE
3uhaEZ+r/PTKxN7/+qh8tGQuhRTI1fC/3rZmDqHQigTJm6pBvy/kDeATVdKevpbZ
brM+1jWITs+c2UkbZLmmIqHEe3JZrkvk6wP96HSTZkopMtyqMUnkdZLwe3MsYtPc
aiB3xGD5K5EZeVOkYAyfbpm0QhuPg9sNF16D+qhoie7vvVOeoKA5wpI8aQ6rnbCc
o/sUUlcMV1UaqeOqazXEEusAzw/Mh6mE7FIgW5f2DWzmu4BKcvbGJBbtxVAjVX6x
omaUjqVVDLXahbZefwC5VuKYe5DySzWFGVCoJ1Jh+kNtvRXRBzsODA2tQcRVKRxH
pYfYhCSN95qFV+EfYuuvRLSsUSqn4jDE2QHzxl6zi0NWvvFWPLAmr8pitEm62E8g
AUY4cbCb+KksTAin1xayDWYuTsmLaMSBkOdo7/HElf0y17a7+FbNy/lzlMylcs23
OCRE6vCa7Pk9dsHC7OlRcG5rEGFnKuZfnZdftM7nUFNtbIozdvGeJzRn9a4roRw2
fWti
=QoKV
-----END PGP MESSAGE-----
"""
  await parse { message }, defer err, mout
  T.no_error err
  T.equal mout.packets().length, 4, "we got 4 packets"
  types = (p.type for p in mout.packets())
  T.equal types, [ 'compressed', 'onepass_sig', 'literal data', 'signature' ], "types are OK"
  T.equal mout.packets()[1].options, "keyid 2FE01C454348DA39", "option correct on onepass_sig"
  T.equal mout.packets()[2].subfields()[1], "raw data: 6 bytes", "subfield 1 on literal"
  cb()
