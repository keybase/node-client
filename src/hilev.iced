
{gpg} = require './gpg'
{decode} = require('pgp-utils').armor

#================================================================

exports.SignatureEngine = class SignatureEngine 

  #------------

  constructor : ({@km}) ->

  #------------

  get_km : -> @km

  #------------

  box : (msg, cb) ->
    out = {}
    arg = 
      stdin : new Buffer(msg, 'utf8')
      args : [ "-u", @km.get_pgp_key_id(), "--sign", "-a" ] 
    await gpg arg, defer err, pgp
    unless err?
      out.pgp = pgp = pgp.toString('utf8')
      [err,msg] = decode pgp
      out.raw = msg.body unless err?
    cb err, out

#================================================================
