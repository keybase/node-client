
{db} = require './db'
{constants} = require './constants'
log = require './log'

##=======================================================================

exports.Track = class Track

  constructor : ({@uid, @sig_chain, @local, @remote}) ->

  #--------

  last : () -> @sig_chain.last()

  #--------

  _skip_remote_check : (track_cert) ->
    rpri = constants.time.remote_proof_recheck_interval
    (track_cert? and 
     (last = @last()?) and 
     (last_check = last?.ctime)? and
     (last_change = track_cert.ctime)? and
     (last_check - last_change > rpri) and
     (track_cert.remote_proofs?.curr is last.id))

  #--------

  skip_remote_check : () ->
    (@_skip_remote_check @local) or (@_skip_remote_check @remote)

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
    track = new Track { uid, sig_chain : trackee.sig_chain, remote  }
    await track.load_local defer err
    track = null if err? 
    log.debug "- loaded tracking info"
    cb err, track

##=======================================================================

