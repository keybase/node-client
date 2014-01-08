
{gpg,assert_no_collision,read_uids_from_key} = require './gpg'
{E} = require './err'
{db} = require './db'
{make_esc} = require 'iced-error'
IS = require('./constants').constants.import_state
log = require './log'
{BufferOutStream} = require 'gpg-wrapper'

#============================================================

strip = (m) -> m.split(/\s+/).join('')

#============================================================

exports.GpgKey = class GpgKey 

  #----------

  constructor : (@user, { secret, import_state }) ->
    @_fingerprint = @user.fingerprint(true) # want the fingerprint in CAPS
    @_username = @user.username()
    @_is_self = @user._is_self
    @_secret = secret
    @_uid = @user.id
    @_public_key_data = @user.public_keys?.primary?.bundle
    @_import_state = import_state

  #----------

  fingerprint : () -> @_fingerprint
  username : () -> @_username
  key_id_64 : () -> @fingerprint()[-16...]
  key_id_32 : () -> @fingerprint()[-8...]

  #----------


  query_key : (cb) ->
    if (fp = @_fingerprint)?
      args = [ "-" + (if @_secret then 'K' else 'k'), fp ]
      await gpg { args, quiet : true }, defer err, out
      if err?
        err = new E.NoLocalKeyError (
          if @_is_self then "You don't have a local key!"
          else "the user #{@_username} doesn't have a local key"
        )
      else
        @_import_state = IS.FINAL
    else
      err = new E.NoRemoteKeyError (
        if @_is_self then "You don't have a registered remote key! Try `keybase push`"
        else "the user #{@_username} doesn't have a remote key"
      )
    cb err

  #--------------

  import_key : (cb) ->
    un = @_username
    uid = @_uid
    fingerprint = @_fingerprint
    found = false
    log.debug "+ #{un}: import public key"
    await @query_key defer err
    if not err? 
      log.debug "| found locally"
      await db.get_import_state { uid, fingerprint }, defer err, @_import_state
      log.debug "| read state from DB as #{@_import_state}"
    else if not (err instanceof E.NoLocalKeyError)? then # noops
    else if not (data = @_public_key_data)?
      err = new E.ImportError "no public key found for #{un}"
    else
      log.debug "| temporarily importing key to scratch GPG keychain"
      @_import_state = IS.TEMPORARY
      await @_db_log defer err
      unless err?
        args = [ "--import" ]
        await @gpg { args, stdin : data, quiet : true }, defer err, out
        if err?
          err = new E.ImportError "#{un}: key import error: #{err.message}"
    log.debug "- #{un}: imported public key (state=#{@_import_state})"
    cb err

  #--------------

  is_tmp : () -> not @_import_state? or (@_import_state is IS.TEMPORARY)

  #--------------

  _remove : (cb) ->
    log.debug "+ deleting public key #{@_username}/#{@_fingerprint}"
    await @gpg { args : [ "--batch", "--delete-keys", @_fingerprint ] }, defer err
    log.debug "- deleted public key #{@_username}/#{@_fingerprint}"
    cb err

  #--------------

  remove : (cb) ->
    await @_remove defer err
    @_import_state = IS.REMOVED
    await @_db_log defer err unless err?
    cb err

  #--------------

  _sign_key : (signer, cb) ->
    log.debug "| GPG-signing #{@username()}'s key with your key"
    args = [ "-u", signer.fingerprint(), "--sign-key", "--batch", "--yes", @fingerprint() ]
    await @gpg { args, quiet : 'true' }, defer err
    cb err

  #--------------

  gpg_obj : () -> gpgmod.obj(@is_tmp())

  #--------------

  _verify_key_id_32 : ( {ki32, which, sig}, cb) ->
    log.debug "+ GpgKey::_verify_key_id_32: #{which}: #{ki32} vs #{@fingerprint()}"
    err = null
    if ki32 isnt @key_id_32() 
      await @gpg { args : [ "--fingerprint", ki32 ] }, defer err, out
      if err? then # noop
      else if not (m = out.toString('utf8').match(/Key fingerprint = ([A-F0-9 ]+)/) )?
        err = new E.VerifyError "Querying for a fingerprint failed"
      else if not (a = strip(m[1])) is (b = @fingerprint())
        err = new E.VerifyError "Fingerprint mismatch: #{a} != #{b}"
      else
        log.debug "| Successful map of #{ki32} -> #{@fingerprint()}"

    unless err?
      await @assert_no_collision ki32, defer err

    log.debug "- GpgKey::_verify_key_id_32: #{which}: #{ki32} vs #{@fingerprint()} -> #{err}"
    cb err

  #--------------

  _find_key_in_stderr : (which, buf) ->
    err = ki32 = fingerprint = null
    d = buf.toString('utf8')
    if (m = d.match(/Primary key fingerprint: (.*)/))? then fingerprint = m[1]
    else if (m = d.match(/using [RD]SA key ID ([A-F0-9]{8})/))? then ki32 = m[1]
    else err = new E.VerifyError "#{which}: can't parse PGP output in verify signature"
    return { err, ki32, fingerprint } 

  #--------------

  verify_sig : ({which, sig, payload}, cb) ->
    log.debug "+ GpgKey::verify_sig #{which}"
    esc = make_esc cb, "GpgKEy::verify_sig"
    err = null

    stderr = new BufferOutStream()
    await @gpg { args : [ "--decrypt"], stdin : sig, stderr }, defer err, out

    # Check that the signature verified, and that the intended data came out the other end
    msg = if err? then "signature verification failed"
    else if ((a = out.toString('utf8')) isnt (b = payload)) then "wrong payload: #{a} != #{b}"
    else null

    # If there's an exception, we can now throw out of this function
    if msg? then await athrow (new E.VerifyError "#{which}: #{msg}") esc defer()

    # Now we need to check that there's a short Key id 32, or a full fingerprint
    # in the stderr output of the verify command
    {err, ki32, fingerprint} = @_find_key_in_stderr which, stderr.data()

    if err then #noop
    else if ki32? 
      await @_verify_key_id_32 { which, ki32, sig }, esc defer()
    else if (a = strip(fingerprint)) isnt (b = @fingerprint())
      err = new E.VerifyError "#{which}: mismatched fingerprint: #{a} != #{b}"

    log.debug "- GpgKey::verify_sig #{which} -> #{err}"
    cb err

  #--------------

  rollback : (cb) ->
    esc = make_esc cb, "GpgKey::commit"
    if @_import_state is IS.TEMPORARY
      un = @_username
      log.debug "+ #{un}: rollback key #{@_fingerprint}"
      stdin = @_public_key_data
      await @_remove esc defer()
      @_import_state = IS.CANCELED
      await @_db_log esc defer()
      log.debug "- #{un}: rollback key #{@_fingerprint}"
    else
      log.debug "| no need to rollback key since it was previously imported"
    cb null

  #--------------

  _db_log : (cb) ->
    log.debug "| DB log update #{@_fingerprint} -> #{@_import_state}"
    await db.log_key_import {uid : @_uid, state : @_import_state, fingerprint : @_fingerprint }, defer err
    cb err

  #--------------

  read_uids_from_key : (cb) ->
    opts = 
      tmp : @is_tmp()
      fingerprint : @_fingerprint
    await read_uids_from_key opts, defer err, uids
    cb err, uids

  #--------------

  gpg : (opts, cb) ->
    opts.tmp = @is_tmp()
    gpg opts, cb

  #--------------

  commit : (signer, cb) ->
    esc = make_esc cb, "GpgKey::commit"
    un = @_username
    if @_import_state is IS.TEMPORARY
      log.debug "+ #{un}: remove temporarily imported public key"
      stdin = @_public_key_data
      await @_remove esc defer()
      @_import_state = IS.FINAL
      await @gpg { args : [ "--import" ], stdin, quiet : true }, esc defer()
      await @_sign_key signer, esc defer()
      await @_db_log esc defer()
      log.debug "- #{un}: remove temporarily imported public key"
    else
      log.debug "| #{un}: Key was previously commited; noop"
    cb null

  #--------------

  assert_no_collision : (short_id, cb) -> 
    assert_no_collision { short_id, tmp : @is_tmp() }, cb


#============================================================

