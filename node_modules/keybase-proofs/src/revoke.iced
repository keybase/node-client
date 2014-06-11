
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Revoke = class Revoke extends Base

  _type : () -> constants.sig_types.revoke

  _v_check : ({json}, cb) ->
    await super { json }, defer err
    unless err?
      err = if not(json.body?.revoke?.sig_id?) and not(json.body?.revoke?.sig_ids?)
        new Error "Missing revoke.sig_ids in signature"
    cb err

#==========================================================================
