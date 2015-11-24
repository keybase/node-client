
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Track = class Track extends Base

  constructor : (obj) ->
    @track = obj.track
    super obj

  _type : () -> constants.sig_types.track

  _required_sections : () -> super().concat(["track"])

  _v_customize_json : (ret) ->
    ret.body.track = @track

#==========================================================================

exports.Untrack = class Untrack extends Base

  constructor : (obj) ->
    @untrack = obj.untrack
    super obj

  _type : () -> constants.sig_types.untrack

  _required_sections : () -> super().concat(["untrack"])

  _v_customize_json : (ret) ->
    ret.body.untrack = @untrack

#==========================================================================
