
{gpg} = require './gpg'
{make_esc} = require 'iced-error'
{E} = require './err'

#======================================================================

exports.KeyManager = class KeyManager 

  constructor : ({@key, @lookup, @fingerprint, @key_id}) ->

  #--------------

  @load : (id,cb) ->
    out = null
    obj = { lookup : id }
    esc = make_esc cb, "KeyManager.load"
    await gpg { args : [ "--export", "-a", id ] }, esc defer obj.key
    await gpg { args : [ "--fingerprint", id ] }, esc defer raw
    if (m = raw.toString().match /Key fingerprint = ([A-F0-9 ]+)/)?
      obj.fingerprint = m[1].replace(new RegExp(" ", "g"), '').toLowerCase()
      obj.key_id = obj.fingerprint[-16...]
      out = new KeyManager obj
    else
      err = new E.GpgError "Got unexpected GPG output when looking for a fingerprint" 
    cb err, out

  #--------------

  get_pgp_key_id      : () -> @key_id
  get_pgp_fingerprint : () -> @fingerprint

#======================================================================
