
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Announcement = class Announcement extends Base

  constructor : (obj) ->
    @announcement = obj.announcement
    super obj

  _type : () -> constants.sig_types.announcement

  _required_sections : () -> super().concat(["announcement"])

  _v_customize_json : (ret) ->
    ret.body.announcement = @announcement

#==========================================================================
