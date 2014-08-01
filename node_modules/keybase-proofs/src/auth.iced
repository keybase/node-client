
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Auth = class Auth extends Base

  constructor : (obj) ->
    @nonce = obj.nonce
    super obj

  _type : () -> constants.sig_types.auth

  _json : () -> 
    ret = super { expire_in : 24*60*60 }
    ret.body.nonce = if @nonce then @nonce.toString('hex') else null
    ret

#==========================================================================
