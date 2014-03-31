
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Revoke = class Revoke extends Base

  constructor : (obj) ->
    @revoke = obj.revoke
    super obj

  _type : () -> constants.sig_types.revoke

  _json : () -> 
    ret = super {}
    ret.body.revoke = @revoke
    ret

  _v_check : ({json}, cb) ->
    await super { json }, defer err
    unless err?
      err = if not json.body?.revoke?.sig_id?
        new Error "Missing revoke.sig_id in signature"
    cb err

#==========================================================================
