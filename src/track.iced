
{db} = require './db'
{constants} = require './constants'
log = require './log'
{proof_type_to_string} = require 'keybase-proofs'
ST = constants.signature_types
deq = require 'deep-equal'
{E} = require './err'
{unix_time} = require('pgp-utils').util

##=======================================================================

exports.TrackWrapper = class TrackWrapper

  constructor : ({@trackee, @local, @remote}) ->
    @uid = @trackee.id
    @sig_chain = @trackee.sig_chain

  #--------

  last : () -> @sig_chain.last()
  table : () -> @sig_chain.table[ST.REMOTE_PROOF]

  #--------

  _check_remote_proof : (rp) ->
    if not (rkp = rp.remote_key_proof)? 
      new E.RemoteProofError "no 'remote_key_proof field'"
    else if ((a = rkp.check_data_json?.name) isnt (b = (proof_type_to_string[rkp.proof_type])))
      new E.RemoteProofError "name mismatch: #{a} != #{b}"
    else if not (link = @sig_chain.lookup rp.curr)?
      new E.RemoteProofError "Failed to find a chain link for #{rp.curr}"
    else if not deq((a = link.body()?.service), (b = rkp.check_data_json))
      log.info "JSON obj mismatch: #{JSON.stringify a} != #{JSON.stringify b}"
      new E.RemoteProofError "The check data was wrong for the signature"
    else null

  #--------

  # Check the tracking object for internal consistency. These checks should
  # actually never fail, unless there was a bug in the client.
  _check_track_obj : (o) ->
    err = null
    if (a = o.id) isnt (b = @trackee.id) 
      err = new E.UidMismatchError "#{a} != #{b}"
    else if ((a = o.basics?.username) isnt (b = @trackee.username()))
      err = new E.UsernameMismatchError "#{a} != #{b}"
    else
      for rp in o.remote_proofs when not err?
        err = @_check_remote_proof rp
    return err 

  #--------

  _skip_remote_check : (which) ->
    track_cert = @[which]
    log.debug "+ _skip_remote_check for #{which}"
    rpri = constants.time.remote_proof_recheck_interval
    _check_all_proofs_ok = (proofs) ->
      for proof in proofs
        return false if proof.remote_key_proof?.state isnt 1
      return true

    prob = if not track_cert?                 then "no track cert given"
    else if not (last = @last())?             then "no last link found"
    else if (last_check = track_cert.ctime)?  then "no last_check"
    else if (unix_time() - last_check > rpri) then "timed out!"
    else if ((a = track_cert.seq_tail?.payload_hash) isnt (b = last.id))
      "id/hash mismatch: #{a} != #{b}"
    else if not (_check_all_proofs_ok track_cert.remote_proofs)
      "all proofs were not OK"

    ret = if prob?
      log.debug "| problem: #{prob}"
      false
    else
      true

    log.debug "- _skip_remote_check -> #{ret}"
    ret

  #--------

  _skip_approval : (which) ->
    track_cert = @[which]
    log.debug "+ skip_approval(#{which})"
    dlen = (d) -> Object.keys(d).length

    prob = if not track_cert? then "no cert found"
    else if ((a = track_cert.key?.key_fingerprint?.toLowerCase()) isnt 
             (b = @trackee.fingerprint?.toLowerCase()))
      "trackee changed keys: #{a} != #{b}"
    else if ((a = track_cert.remote_proofs.length) isnt (b = dlen(@table())))
      "number of remote IDs changed: #{a} != #{b}"
    else
      tmp = null
      for rp in track_cert.remote_proofs
        rkp = rp.remote_key_proof
        if not deq((a = rkp.check_data_json), (b = @table()[rkp.proof_type]?.body()?.service))
          tmp = "Remote ID changed: #{JSON.stringify a} != #{JSON.stringify b}"
          break
      tmp

    ret = true
    if prob?
      log.debug "| failure: #{prob}"
      ret = false

    log.debug "- skip_approval(#{which}) -> #{ret}"
    ret

  #--------

  skip_remote_check : () ->
    if (@_skip_remote_check 'remote') then constants.skip.REMOTE
    else if (@_skip_remote_check 'local') then constants.skip.LOCAL
    else constants.skip.NONE

  #--------

  # We need approval before accepting if:
  #  1. the key changed
  #  2. an identity was deleted or added or changed
  # If we have acceptance on either local or remote, we can leave it as is.
  skip_approval : () ->
    if (@_skip_approval 'remote') then constants.skip.REMOTE
    else if (@_skip_approval 'local') then constants.skip.LOCAL
    else constants.skip.NONE

  #--------

  load_local : (cb) ->
    log.debug "+ getting local tracking info from DB"
    await db.get { type : constants.ids.local_track, key : @uid }, defer err, value
    @local = value
    log.debug "- completed, with result: #{!!value}"
    cb err

  #--------

  store_local : (obj, cb) ->
    log.debug "+ storing local track object"
    await db.put { type : constants.ids.local_track, key : @uid, value : obj }, defer err
    log.debug "- stored local track object"
    cb err

  #--------

  check : () ->
    if @local 
      if (e = @_check_track_obj @local)?
        log.warn "Local tracking object was invalid: #{e.message}"
        @local = null
      else
        log.debug "| local track checked out"
    if @remote? 
      if (e = @_check_track_obj @remote)?
        log.warn "Remote tracking object was invalid: #{e.message}"
        @remote = null
      else
        log.debug "| remote track checked out"

  #--------

  @load : ({tracker, trackee}, cb) ->
    uid = trackee.id
    remote = tracker?.sig_chain?.get_track_obj uid
    log.debug "+ loading Tracking info w/ remote=#{!!remote}"
    track = new TrackWrapper { uid, trackee, remote  }
    await track.load_local defer err
    track = null if err? 
    track?.check()
    log.debug "- loaded tracking info"
    cb err, track

##=======================================================================

