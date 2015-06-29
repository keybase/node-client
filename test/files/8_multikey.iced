fs      = require 'fs'
path    = require 'path'
{User, signup} = require '../lib/user'
{prng}  = require 'crypto'
{make_esc} = require 'iced-error'
kbpgp = require 'kbpgp'

# These tests are for exercising compatibility with the Go client. In
# particular, we want to interact with users who have new-style sigchains, with
# sibkeys and multiple PGP keys. "t_frank" is a user who started with a PGP key
# generated on the site but then logged in with the Go client to generate a
# second PGP key. "t_george" is a user who signed up on the Go client and just
# used that to generate two PGP keys. We check that encrypt works against all
# the recipient's keys, and that the implicit `id` passes against fingerprint
# assertions.

frank_assertions = 'fingerprint://7e67 && fingerprint://961a'
frank_subkeys = [
  'B71076EF6D3C8592'
  'B08DEF7366BFF230'
]

george_assertions = 'fingerprint://10a7 && fingerprint://d4e0'
george_subkeys = [
  'F8BDEF9FE310B565'
  '7E912C6DA3007BA0'
]

me = null

exports.init = (T,cb) ->
  await signup T, "multi", {}, defer _me
  me = _me
  cb()

encrypt_test = ({T, recipient, assertions, subkeys}, cb) ->
  args = ["encrypt", recipient, "-m", "foo", "--batch", "--assert", assertions]
  await me.keybase {args}, defer err, out
  T.no_error err
  armored = out.toString()
  [err, msg] = kbpgp.armor.decode armored
  T.no_error err
  [err, packets] = kbpgp.parser.parse msg.body
  recipient_key_ids = []
  for packet in packets
    if packet.key_id?
      recipient_key_ids.push(packet.key_id.toString('hex').toUpperCase())
  T.equal subkeys.sort(), recipient_key_ids.sort()
  cb()

exports.encrypt_to_frank = (T, cb) ->
  await encrypt_test {
      T,
      recipient: "t_frank",
      assertions: frank_assertions,
      subkeys: frank_subkeys
    }, defer()
  cb()

exports.encrypt_to_george = (T, cb) ->
  await encrypt_test {
      T,
      recipient: "t_george",
      assertions: george_assertions,
      subkeys: george_subkeys
    }, defer()
  cb()
