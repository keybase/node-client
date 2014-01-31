
{GPG} = require 'gpg-wrapper'
{env} = require './env'
log = require './log'
util = require 'util'
{E} = require './err'

#============================================================

exports.gpg = (inargs, cb) -> 
  log.debug "| Call to gpg: #{util.inspect(inargs)}"
  inargs.quiet = false if inargs.quiet and env().get_debug()
  (new GPG).run(inargs, cb)

#====================================================================

exports.parse_signature = (lines) -> 
  strip = (m) -> if m? then m.split(/\s+/).join('') else null
  ends_in = (a,b) -> a[-(b.length)...] is b
  rxx = ///
            (?:^|\n)gpg:\sSignature\smade.*\n
            gpg:\s+using\s[RD]SA\skey\s([A-F0-9]{16})\n
            (?:.*\n)* # Skip arbirarily many lines
            gpg:\sGood\ssignature\sfrom.*\n
            (?:.*\n)* # Skip arbirarily many lines
            Primary\skey\sfingerprint:\s([A-F0-9\s]+)\n
            (?:\s+Subkey\sfingerprint:\s([A-F0-9\s]+)\n)?
       /// 
  err = ret = null
  if not (m = lines.match rxx)? 
    err = new E.NotFoundError "no signature found"
  else
    ret =
      primary : strip(m[2])
      subkey :  strip(m[3])
    unless ends_in(ret.primary, m[1]) or ends_in(ret.subkey, m[1])
      err = new E.VerifyError "key ID didn't match fingerprint"
      ret = null
  [err, ret]

#====================================================================
