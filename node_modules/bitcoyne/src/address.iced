kbpgp = require 'kbpgp'
{SHA256} = kbpgp.hash
{base58} = kbpgp
{bufeq_secure} = require('pgp-utils').util

#======================================================================

decode = (s) ->
  try
    buf = base58.decode s
    return [ null, buf]
  catch err
    return [err, null]

#==============================
    

exports.check = check = (s, opts = {}) ->
  versions = opts.versions or [0,5]
  [err,buf] = decode s
  return [err,null] if err?
  v = buf.readUInt8 0
  err = if not (v in versions) then new Error "Bad version found: #{v}"
  else
    pkhash = buf[0...-4]
    checksum1 = buf[-4...]
    checksum2 = (SHA256 SHA256 pkhash)[0...4]
    if not bufeq_secure checksum1, checksum2
      new Error "Checksum mismatch"
    else null
  ret = if err? then null else { version : v, pkhash : pkhash[1...] }
  return [err, ret]

#======================================================================

