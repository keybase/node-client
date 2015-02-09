
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Device = class Device extends Base

  constructor : (obj) ->
    @device = obj.device
    super obj

  _type : () -> constants.sig_types.device

  _json : () ->
    ret = super {}
    ret.body.device = @device
    return ret

#==========================================================================
