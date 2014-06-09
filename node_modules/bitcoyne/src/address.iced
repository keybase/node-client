
kbpgp = require 'kbpgp'
{SHA256} = kbpgp.hash
{base58} = kbpgp
{bufeq_secure} = require('pgp-utils').util

exports.check = check = (s, opts = {}) ->
  versions = opts.versions or [0,5]
  buf = base58.decode s
  v = buf.readUInt8 0
  if not (v in versions) then new Error "Bad version found: #{v}"
  else
    pkhash = buf[0...-4]
    checksum1 = buf[-4...]
    checksum2 = (SHA256 SHA256 pkhash)[0...4]
    if not bufeq_secure checksum1, checksum2
      new Error "Checksum mismatch"
    else null

