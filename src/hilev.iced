
{gpg} = require './gpg'

#================================================================

exports.SignatureEngine = class SignatureEngine 

  #------------

  constructor : ({@km}) ->

  #------------

  get_km : -> @km

  #------------

  box : (msg, cb) ->
    arg = 
      stdin : new Buffer(msg, 'utf8')
      args : [ "-u", @km.get_pgp_key_id(), "--sign" ] 
    await gpg arg, defer err, out
    cb err, out

#================================================================
