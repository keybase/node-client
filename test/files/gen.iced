
kbpgp = require 'kbpgp'
{make_esc} = require 'iced-error'

gen = (cb) ->
  esc = make_esc cb, "gen"
  F = kbpgp.const.openpgp.key_flags
  nbits = 1024
  args = {
    primary : {
      flags : F.certify_keys | F.sign_data | F.auth
      nbits : nbits
    }
    subkeys : [{
      flags : F.encrypt_comm | F.encrypt_stroage
      nbits : nbits
    }]
    userid : "Alice Tester <alice@test.com>"
  }
  await kbpgp.KeyManager.generate args, esc defer km
  await km.sign {}, esc defer()
  await km.export_pgp_public {}, esc defer out
  console.log out
  cb null

rc = 0
await gen defer err
if err?
  rc = -2
  console.error err.toString()
process.exit rc


