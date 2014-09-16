
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Subkey = class Subkey extends Base

  constructor : (obj) ->
    @subkey = obj.subkey
    super obj

  _type : () -> constants.sig_types.subkey

  _json : () -> 
    ret = super {}
    ret.body.subkey = @subkey
    return ret

#==========================================================================
