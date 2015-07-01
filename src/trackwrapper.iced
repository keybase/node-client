
{db} = require './db'
{constants} = require './constants'
log = require './log'
proofs = require 'keybase-proofs'
{proof_type_to_string} = proofs
PT = proofs.constants.proof_types
ST = constants.signature_types
deq = require 'deep-equal'
{E} = require './err'
{unix_time} = require('pgp-utils').util
{make_esc} = require 'iced-error'
{prompt_yn} = require './prompter'
{session} = require './session'
db = require './db'
util = require 'util'
{env} = require './env'
scrapers = require './scrapers'
{Link} = require './sigchain'
{CHECK} = require './display'

##=======================================================================

exports.TrackWrapper = class TrackWrapper

  constructor : ({@trackee, @tracker, @local, @remote}) ->
    @uid = @trackee.id
    @sig_chain = @trackee.sig_chain
    @_ft = null

  #--------

  last : () -> @sig_chain.last()
  table : () -> @sig_chain.table?.get(ST.REMOTE_PROOF)?.to_dict() or {}

  #--------

  flat_table : () ->
    @_ft = @sig_chain.flattened_remote_proofs() if not @_ft?
    return @_ft

  #--------

  _check_remote_proof : (rp) ->
    proofs_with_service_names = [ PT.twitter, PT.github, PT.reddit, PT.coinbase, PT.hackernews ]
    if not (rkp = rp.remote_key_proof)?
      new E.RemoteProofError "no 'remote_key_proof field'"
    else if not (stub = scrapers.alloc_stub(rkp.proof_type))?
      new E.RemoteProofError "Can't allocate a scraper stub for #{rkp.proof_type}"
    else if not stub.check_proof(d = rkp.check_data_json)
      new E.RemoteProofError "Bad proof found, for check data: #{JSON.stringify d}"
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

    prob = if not track_cert?                     then "no track cert given"
    else if not (last = @last())?                 then "no last link found"
    else if not (last_check = track_cert.ctime)?  then "no last_check"
    else if (unix_time() - last_check > rpri)     then "timed out!"
    else if not (@sig_chain.is_track_fresh(a = track_cert.seq_tail?.payload_hash))
      "we've signed link #{a} which is no longer a fresh track"
    else if not (_check_all_proofs_ok track_cert.remote_proofs)
      "all proofs were not OK"

    ret = if prob?
      log.debug "| problem: #{prob}"
      log.debug "| track cert: #{JSON.stringify track_cert}" if track_cert?
      log.debug "| last link: #{JSON.stringify last}" if last?
      false
    else
      log.debug "| Timing was ok: #{unix_time()} - #{last_check} < #{rpri}"
      true

    log.debug "- _skip_remote_check -> #{ret}"
    ret

  #--------

  _skip_approval : (which) ->
    track_cert = @[which]
    log.debug "+ skip_approval(#{which})"
    dlen = (d) -> if d? then Object.keys(d).length else 0

    prob = if not track_cert? then "no cert found"
    else if ((a = track_cert.key?.kid) isnt (b = @trackee.merkle_data?.eldest_kid))
      "trackee changed keys: #{a} != #{b}"
    else if ((a = track_cert.remote_proofs.length) isnt (b = @flat_table().length))
      "number of remote IDs changed: #{a} != #{b}"
    else
      tmp = null
      for rp in track_cert.remote_proofs
        rkp = rp.remote_key_proof
        row = @table()[rkp.proof_type]
        if not row?
          tmp = "Proof deleted: #{JSON.stringify rkp.check_data_json}"
          break
        else
          unless row.is_leaf()
            sub_id = scrapers.alloc_stub(rkp.proof_type).get_sub_id(rkp.check_data_json)
            row = row.get(sub_id)
          unless row?
            tmp = "Missing sub ID: #{JSON.stringify rkp.proof_type}"
            break
          if not row.is_leaf()
            tmp = "Got bad link, it wasn't a link at all (for proof type: #{rkp.proof_type})"
            break
          else if not deq((a = rkp.check_data_json), (b = row?.body()?.service))
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
    ret = if (@_skip_remote_check 'remote') then constants.skip.REMOTE
    else if (@_skip_remote_check 'local') then constants.skip.LOCAL
    else constants.skip.NONE
    log.debug "| skip_remote_check -> #{ret}"
    return ret

  #--------

  # We need approval before accepting if:
  #  1. the key changed
  #  2. an identity was deleted or added or changed
  # If we have acceptance on either local or remote, we can leave it as is.
  skip_approval : () ->
    ret = if (@_skip_approval 'remote') then constants.skip.REMOTE
    else if (@_skip_approval 'local') then constants.skip.LOCAL
    else constants.skip.NONE
    log.debug "| skip_approval -> #{ret}"
    return ret

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
    log.info "#{CHECK} Wrote tracking info to local database"
    log.debug "- stored local track object"
    cb err

  #--------

  @remove_local_track : ({uid}, cb) ->
    log.debug "+ removing local track object for #{uid}"
    await db.remove {
      type : constants.ids.local_track
      key : uid
      optional : true
    }, defer err
    log.debug "- removed local track object -> #{err}"
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

  is_tracking : () -> { remote : !!@remote, local : !!@local }

  #--------

  store_remote : (cb) ->
    esc = make_esc cb, "TrackWrapper::store_remote"
    await @tracker.gen_track_proof_gen { @uid, @track_obj }, esc defer g
    await g.run esc defer()
    log.info "#{CHECK} Wrote tracking info to remote keybase.io server"
    cb null

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

