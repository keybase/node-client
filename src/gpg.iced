
{GPG} = require 'gpg-wrapper'
{env} = require './env'
log = require './log'
util = require 'util'
{E} = require './err'

#============================================================

exports.gpg = (inargs, cb) -> 
  log.debug "| Call to gpg: #{util.inspect(inargs)}"
  inargs.quiet = false if inargs.quiet and env().get_debug()
  gpg = new GPG
  await gpg.run inargs, defer err, out
  cb err, out

#====================================================================

exports.parse_signature = (lines) -> 
  strip = (m) -> if m? then m.split(/\s+/).join('') else null
  ends_in = (a,b) -> a[-(b.length)...] is b
  rxx = ///
            (?:^|\n)gpg:\sSignature\smade\s(.*?)\r?\n
            gpg:\s+using\s[RD]SA\skey\s([A-F0-9]{16})\r?\n
            (?:.*\r?\n)* # Skip arbirarily many lines
            gpg:\sGood\ssignature\sfrom.*\r?\n
            (?:.*\r?\n)* # Skip arbirarily many lines
            Primary\skey\sfingerprint:\s([A-F0-9\s]+)\r?\n
            (?:\s+Subkey\sfingerprint:\s([A-F0-9\s]+)\r?\n)?
       /// 
  err = ret = null
  if not (m = lines.match rxx)? 
    err = new E.NotFoundError "no signature found"
  else
    ret =
      primary : strip(m[3])
      subkey :  strip(m[4])
      timestamp : m[1]
    unless ends_in(ret.primary, m[2]) or ends_in(ret.subkey, m[2])
      err = new E.VerifyError "key ID didn't match fingerprint"
      ret = null
  [err, ret]

#====================================================================
