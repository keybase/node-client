
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.Track = class Track extends Base

  constructor : (obj) ->
    @track = obj.track
    super obj

  _type : () -> constants.sig_types.track

  _json : () -> 
    ret = super {}
    ret.body.track = @track
    return ret

#==========================================================================

exports.Untrack = class Untrack extends Base

  constructor : (obj) ->
    @untrack = obj.untrack
    super obj

  _type : () -> constants.sig_types.untrack

  _json : () -> 
    ret = super {}
    ret.body.untrack = @untrack
    return ret

#==========================================================================
