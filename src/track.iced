
{db} = require './db'
{constants} = require './constants'
log = require './log'

##=======================================================================

exports.Track = class Track

  constructor : ({@uid, @local, @remote}) ->

  #--------

  load_local : (cb) ->
    log.debug "+ getting local tracking info from DB"
    await db.get { type : constants.ids.local_track, key : @uid }, defer err, value
    @local = value
    log.debug "- completed, with result: #{!!value}"
    cb err

  #--------

  @load : ({tracker, trackee}, cb) ->
    log.debug "+ loading Tracking info w/ remote=#{!!remote}"
    uid = trackee.id
    remote = tracker?.sig_chain?.get_track uid
    track = new Track { uid , remote }
    await track.load_local defer err
    track = null unless err? 
    log.debug "- loaded tracking info"
    cb err, track

##=======================================================================

