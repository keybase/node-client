
{db} = require './db'
{constants} = require './constants'
log = require './log'
proofs = require 'keybase-proofs'
{proof_type_to_string} = proofs
ST = constants.signature_types
deq = require 'deep-equal'
{E} = require './err'
{unix_time} = require('pgp-utils').util
{make_esc} = require 'iced-error'
{prompt_yn} = require './prompter'
colors = require 'colors'
{session} = require './session'
{User} = require './user'
db = require './db'
util = require 'util'
{env} = require './env'

##=======================================================================

exports.TrackWrapper = class TrackWrapper

  constructor : ({@trackee, @tracker, @local, @remote}) ->
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
    else if ((a = track_cert.key?.key_fingerprint) isnt (b = @trackee.fingerprint()))
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

  store_local : (cb) ->
    log.debug "+ storing local track object"
    type = constants.ids.local_track
    await db.put { type, key : @uid, value : @track_obj }, defer err
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
    track = new TrackWrapper { uid, trackee, tracker, remote  }
    await track.load_local defer err
    track = null if err? 
    track?.check()
    log.debug "- loaded tracking info"
    cb err, track

  #--------

  is_tracking : () -> !!@remote

  #--------

  store_remote : (cb) ->
    await @tracker.gen_track_proof_gen { @uid, @track_obj }, defer err, g
    await g.run defer err unless err?
    cb err

  #--------

  store_track : ({do_remote}, cb) ->
    esc = make_esc cb, "TrackWrapper::store_track"
    log.debug "+ track user (remote=#{do_remote})"
    @track_obj = @trackee.gen_track_obj()
    log.debug "| object generated: #{JSON.stringify @track_obj}"
    if do_remote
      await @store_remote esc defer()
    else
      await @store_local esc defer()
    log.debug "- tracked user"
    cb null

##=======================================================================

exports.TrackSubSubCommand = class TrackSubSubCommand

  #----------------------

  constructor : ({@args, @opts}) ->

  #----------------------

  prompt_ok : (warnings, cb) ->
    prompt = if warnings
      log.console.log colors.red "Some remote proofs failed!"
      "Still verify this user?"
    else
      "Are you satisfied with these proofs?"
    await prompt_yn { prompt, defval : false }, defer err, ret
    cb err, ret

  #----------

  prompt_track : (cb) ->
    ret = err = null
    if @opts.remote then ret = true
    else if (@opts.batch or @opts.local) then ret = false
    else
      prompt = "Permnanently track this user, and write proof to server?"
      await prompt_yn { prompt, defval : true }, defer err, ret
    cb err, ret

  #----------

  run : (cb) ->
    esc = make_esc cb, "Verify::run"
    log.debug "+ run"

    await User.load_me esc defer me

    await User.load { username : @args.them }, esc defer them
    await them.import_public_key esc defer found

    # After this point, we have to recover any errors and throw away 
    # our key is necessary. So call into a subfunction.
    await @_run2 {me, them}, defer err, accept

    if accept 
      log.debug "| commit_key"
      await them.commit_key esc defer()
    else if not found
      log.debug "| remove_key"
      await them.remove_key esc defer()

    log.debug "- run"
    cb err

  #----------

  _run2 : ({me, them}, cb) ->
    esc = make_esc cb, "Verify::_run2"
    log.debug "+ _run2"

    await them.verify esc defer()
    await TrackWrapper.load { tracker : me, trackee : them }, esc defer trackw
    
    check = trackw.skip_remote_check()
    if (check is constants.skip.NONE)
      log.console.log "...checking identity proofs"
      skp = false
    else 
      log.info "...all remote checks are up-to-date"
      skp = true
    await them.check_remote_proofs skp, esc defer warnings
    n_warnings = warnings.warnings().length

    if ((approve = trackw.skip_approval()) isnt constants.skip.NONE)
      log.debug "| skipping approval, since remote services & key are unchanged"
      accept = true
    else if @opts.batch
      log.debug "| We needed approval, but we were in batch mode"
      accept = false
    else
      await @prompt_ok n_warnings, esc defer accept

    err = null
    if not accept
      log.warn "Bailing out; proofs were not accepted"
      err = new E.CancelError "operation was canceled"
    else if (check is constants.skip.REMOTE) and (approve is constants.skip.REMOTE)
      log.info "Nothing to do; tracking is up-to-date"
    else
      await @prompt_track esc defer do_remote
      await session.load_and_login esc defer() if do_remote
      await trackw.store_track { do_remote }, esc defer()

    log.debug "- _run2"
    cb err, accept 

##=======================================================================
