{bufeq_secure,athrow, a_json_parse} = require('iced-utils').util
{make_esc} = require 'iced-error'
kbpgp = require('kbpgp')
proofs = require('keybase-proofs')
ie = require('iced-error')

UID_LEN = 32
exports.SIG_ID_SUFFIX = SIG_ID_SUFFIX = "0f"

# For testing that caches are working properly. (Use a wrapper object instead
# of a simple counter because main.iced copies things.)
exports.debug =
  unbox_count: 0

exports.ParsedKeys = ParsedKeys = class ParsedKeys
  @parse : ({key_bundles}, cb) ->
    # We only take key bundles from the server, either hex NaCl public keys, or
    # ascii-armored PGP public key strings. We compute the KIDs and
    # fingerprints ourselves, because we don't trust the server to do it for
    # us.
    esc = make_esc cb, "ParsedKeys.parse"
    default_eldest_kid_for_testing = null
    opts = { time_travel : true }
    parsed_keys = new ParsedKeys
    for bundle in key_bundles
      await kbpgp.ukm.import_armored_public {armored: bundle, opts}, esc defer key_manager
      await parsed_keys._add_key {key_manager}, esc defer()
      default_eldest_kid_for_testing or= key_manager.get_ekid().toString "hex"
    cb null, parsed_keys, default_eldest_kid_for_testing

  constructor : ->
    # Callers should use this class to get KeyManagers for KIDs they already
    # have, but callers MUST NOT iterate over the set of KIDs here as though it
    # were the valid set for a given user. The set of KIDs is *untrusted*
    # because it comes from the server. We keep the map private to prevent that
    # mistake.
    @_kids_to_merged_pgp_key_managers = {}
    @_kids_to_pgp_key_managers_by_hash = {}
    @_kids_to_nacl_keys = {}

  _add_key : ({key_manager}, cb) ->
    esc = make_esc "ParsedKeys._add_key"
    kid = key_manager.get_ekid()
    kid_str = kid.toString "hex"

    if key_manager.pgp?
      if (existing = @_kids_to_merged_pgp_key_managers[kid_str])?
        existing.merge_everything key_manager
      else
        @_kids_to_merged_pgp_key_managers[kid_str] = key_manager
      await key_manager.pgp_full_hash {}, esc defer hash
      (@_kids_to_pgp_key_managers_by_hash[kid_str] or= {})[hash] = key_manager
    else
      @_kids_to_nacl_keys[kid_str] = key_manager
    cb()

  # We may have multiple versions of a PGP key with the same KID/fingerprint.
  # They could have different subkeys and userids, and an old subkey could have
  # been used to sign an old link. We historically handled handle these cases
  # by merging all versions of a PGP key together, but since it's valid to
  # upload a new version of a PGP key specifically to revoke a subkey and
  # prevent it from signing new chainlinks, we realized that it's necessary to
  # track which version of the key is active. When a PGP key is signed in or
  # updated, the hash of the ASCII-armored public key is now specified in the
  # sigchain.
  #
  # get_merged_pgp_key_manager must only be used when a hash hasn't been
  # specified (in, say, an old sigchain). When an eldest, sibkey, or pgp_update
  # link specifies a hash, get_pgp_key_manager_with_hash must be used for all
  # following links signed by that KID.

  get_merged_pgp_key_manager : (kid) ->
    @_kids_to_merged_pgp_key_managers[kid]

  get_pgp_key_manager_with_hash : (kid, hash) ->
    @_kids_to_pgp_key_managers_by_hash[kid]?[hash]

  get_nacl_key_manager : (kid) ->
    @_kids_to_nacl_keys[kid]

# KeyState tracks hashes that have been specified for PGP keys. As long as it's
# kept up to date as the sigchain is replayed, it can safely be used to get the
# correct KeyManager for a given KID.
class KeyState
  constructor : ({@parsed_keys}) ->
    @_kid_to_hash = {}

  set_key_hash : ({kid, hash}, cb) ->
    if not @parsed_keys.get_pgp_key_manager_with_hash(kid, hash)?
      cb new E.NoKeyWithThisHashError "No PGP key with kid #{kid} and hash #{hash} exists"
    @_kid_to_hash[kid] = hash
    cb()

  get_key_manager : (kid) ->
    if (key = @parsed_keys.get_nacl_key_manager kid)?
      return key
    if (hash = @_kid_to_hash[kid])?
      return @parsed_keys.get_pgp_key_manager_with_hash kid, hash
    return @parsed_keys.get_merged_pgp_key_manager kid

class ChainLink
  @parse : ({sig_blob, key_state, sig_cache}, cb) ->
    esc = make_esc cb, "ChainLink.parse"
    # Unbox the signed payload. PGP key expiration is checked automatically
    # during unbox, using the ctime of the chainlink.
    await @_unbox_payload {sig_blob, key_state, sig_cache}, esc defer payload, sig_id, payload_hash
    # Check internal details of the payload, like uid length.
    await check_link_payload_format {payload}, esc defer()
    # Make sure the KID from the server matches the payload, and that any
    # payload PGP fingerprint also matches the KID.
    await @_check_payload_against_server_kid {sig_blob, payload, key_state}, esc defer()
    # Check any reverse signatures.
    await @_check_reverse_signatures {payload, key_state}, esc defer()
    # The constructor takes care of all the payload parsing that isn't failable.
    cb null, new ChainLink {kid: sig_blob.kid, sig_id, payload, payload_hash}

  @_unbox_payload : ({sig_blob, key_state, sig_cache}, cb) ->
    esc = make_esc cb, "ChainLink._unbox_payload"
    # Get the signing KID directly from the server blob. We'll confirm later
    # that this is the same as the KID listed in the payload.
    kid = sig_blob.kid
    # Get the key_manager and sig_eng we need from the ParsedKeys object.
    key_manager = key_state.get_key_manager kid
    if not key_manager?
      await athrow (new E.NonexistentKidError "link signed by nonexistent kid #{kid}"), esc defer()
    sig_eng = key_manager.make_sig_eng()
    # We need the signing ctime to verify the signature, and that's actually in
    # the signed payload. So we fully parse the payload *before* verifying, and
    # do the actual (maybe cached) verification at the end.
    await sig_eng.get_body_and_unverified_payload(
      {armored: sig_blob.sig}, esc defer sig_body, unverified_buffer)
    sig_id = kbpgp.hash.SHA256(sig_body).toString("hex") + SIG_ID_SUFFIX
    payload_hash = kbpgp.hash.SHA256(unverified_buffer).toString("hex")
    payload_json = unverified_buffer.toString('utf8')
    await a_json_parse payload_json, esc defer payload
    ctime_seconds = payload.ctime
    # Now that we have the ctime, get the verified payload.
    if sig_cache?
      await sig_cache.get {sig_id}, esc defer verified_buffer
    if not verified_buffer?
      exports.debug.unbox_count++
      await key_manager.make_sig_eng().unbox(
        sig_blob.sig,
        defer(err, verified_buffer),
        {now: ctime_seconds})
      if err?
        await athrow (new E.VerifyFailedError err.message), esc defer()
      if sig_cache?
        await sig_cache.put {sig_id, payload_buffer: verified_buffer}, esc defer()
    # Check that what we verified matches the unverified payload we used above.
    # Ideally it should be impossible for there to be a difference, but this
    # protects us from bugs/attacks that might exploit multiple payloads,
    # particularly in PGP.
    await check_buffers_equal verified_buffer, unverified_buffer, esc defer()
    # Success!
    cb null, payload, sig_id, payload_hash

  @_check_payload_against_server_kid : ({sig_blob, payload, key_state}, cb) ->
    # Here's where we check the data we relied on in @_unbox_payload().
    signing_kid = sig_blob.kid
    signing_fingerprint = key_state.get_key_manager(signing_kid).get_pgp_fingerprint()?.toString('hex')
    payload_kid = payload.body.key.kid
    payload_fingerprint = payload.body.key.fingerprint
    err = null
    if payload_kid? and payload_kid isnt signing_kid
      err = new E.KidMismatchError "signing kid (#{signing_kid}) and payload kid (#{payload_kid}) mismatch"
    else if payload_fingerprint? and payload_fingerprint isnt signing_fingerprint
      err = new E.FingerprintMismatchError "signing fingerprint (#{signing_fingerprint}) and payload fingerprint (#{payload_fingerprint}) mismatch"
    cb err

  @_check_reverse_signatures : ({payload, key_state}, cb) ->
    esc = make_esc cb, "ChainLink._check_reverse_signatures"
    if payload.body.sibkey?
      kid = payload.body.sibkey.kid
      full_hash = payload.body.sibkey.full_hash
      sibkey_key_manager = if full_hash?
        # key_state hasn't been updated with the new sibkey's full hash yet
        key_state.parsed_keys.get_pgp_key_manager_with_hash kid, full_hash
      else
        key_state.get_key_manager kid
      if not sibkey_key_manager?
        await athrow (new E.NonexistentKidError "link reverse-signed by nonexistent kid #{kid}"), esc defer()
      sibkey_proof = new proofs.Sibkey {}
      await sibkey_proof.reverse_sig_check {json: payload, subkm: sibkey_key_manager}, defer err
      if err?
        await athrow (new E.ReverseSigVerifyFailedError err.message), esc defer()
    if payload.body.subkey?
      kid = payload.body.subkey.kid
      subkey_key_manager = key_state.get_key_manager kid
      if not subkey_key_manager?
        await athrow (new E.NonexistentKidError "link delegates nonexistent subkey #{kid}"), esc defer()
    cb null

  constructor : ({@kid, @sig_id, @payload, @payload_hash}) ->
    @uid = @payload.body.key.uid
    @username = @payload.body.key.username
    @seqno = @payload.seqno
    @prev = @payload.prev
    # @fingerprint is PGP-only.
    @fingerprint = @payload.body.key.fingerprint
    # Not all links have the "eldest_kid" field, but if they don't, then their
    # signing KID is implicitly the eldest.
    @eldest_kid = @payload.body.key.eldest_kid or @kid
    @ctime_seconds = @payload.ctime
    @etime_seconds = @ctime_seconds + @payload.expire_in

    # Only expected to be set in eldest links
    @signing_key_hash = @payload.body.key.full_hash

    @sibkey_delegation = @payload.body.sibkey?.kid
    @sibkey_hash = @payload.body.sibkey?.full_hash

    @subkey_delegation = @payload.body.subkey?.kid

    @pgp_update_kid = @payload.body.pgp_update?.kid
    @pgp_update_hash = @payload.body.pgp_update?.full_hash

    @key_revocations = []
    if @payload.body.revoke?.kids?
      @key_revocations = @payload.body.revoke.kids
    if @payload.body.revoke?.kid?
      @key_revocations.push(@payload.body.revoke.kid)

    @sig_revocations = []
    if @payload.body.revoke?.sig_ids?
      @sig_revocations = @payload.body.revoke.sig_ids
    if @payload.body.revoke?.sig_id?
      @sig_revocations.push(@payload.body.revoke.sig_id)


# Exported for testing.
exports.check_link_payload_format = check_link_payload_format = ({payload}, cb) ->
  esc = make_esc cb, "check_link_payload_format"
  uid = payload.body.key.uid
  if uid.length != UID_LEN
    await athrow (new E.BadLinkFormatError "UID wrong length: #{uid.length}"), esc defer()
  cb()


# Also exported for testing. This check will never fail under normal
# circumstances, so we need a test to explicitly make it fail.
exports.check_buffers_equal = check_buffers_equal = (verified_buffer, unverified_buffer, cb) ->
  err = null
  if not bufeq_secure(verified_buffer,unverified_buffer)
    msg = """Payload mismatch!
             Verified:
             #{verified_buffer.toString('hex')}
             Unverified:
             #{unverified_buffer.toString('hex')}"""
    err = new E.VerifyFailedError msg
  cb err


exports.SigChain = class SigChain

  # The replay() method is the main interface for all callers. It checks all of
  # the user's signatures and returns a SigChain object representing their
  # current state.
  #
  # @param {[string]} sig_blobs The parsed JSON signatures list returned from
  #     the server's sig/get.json endpoint.
  # @param {ParsedKeys} parsed_keys The unverified collection of all the user's
  #     public keys. This is usually obtained from the all_bundles list given
  #     by user/lookup.json, passed to ParsedKeys.parse(). NaCl public key
  #     material is contained entirely within the KID, so technically all this
  #     extra data is only needed for PGP, but we treat both types of keys the
  #     same way for simplicity.
  # @param {object} sig_cache An object with two methods: get({sig_id}, cb) and
  #     put({sig_id, payload_buffer}, cb), which caches the payloads of
  #     previously verified signatures. This parameter can be null, in which
  #     case all signatures will be checked.
  # @param {string} uid Used only to check that the sigchain belongs to the
  #     right user.
  # @param {string} username As with uid, used for confirming ownership.
  # @param {string} eldest_kid The full (i.e. with-prefix) KID of the user's
  #     current eldest key. This is used to determine the latest subchain.
  # @param {object} log An object with logging methods (debug, info, warn,
  #     error). May be null.
  @replay : ({sig_blobs, parsed_keys, sig_cache, uid, username, eldest_kid, log}, cb) ->
    log = log or (() ->)
    log "+ libkeybase: replay(username: #{username}, uid: #{uid}, eldest: #{eldest_kid})"
    esc = make_esc cb, "SigChain.replay"
    # Forgetting the eldest KID would silently give you an empty sigchain. Prevent this.
    if not eldest_kid?
      await athrow (new Error "eldest_kid parameter is required"), esc defer()
    # Initialize the SigChain.
    key_state = new KeyState {parsed_keys}
    sigchain = new SigChain {uid, username, eldest_kid, key_state}
    # Build the chain link by link, checking consistency all the way through.
    for sig_blob in sig_blobs
      log "| libkeybase: replaying signature #{sig_blob.seqno}: #{sig_blob.sig_id}"
      await sigchain._add_new_link {sig_blob, sig_cache, log}, esc defer()
    # After the chain is finished, make sure we've proven ownership of the
    # eldest key in some way.
    await sigchain._enforce_eldest_key_ownership {}, esc defer()
    log "- libkeybase: replay finished"
    cb null, sigchain

  # NOTE: Don't call the constructor directly. Use SigChain.replay().
  constructor : ({uid, username, eldest_kid, key_state}) ->
    @_uid = uid
    @_username = username
    @_eldest_kid = eldest_kid
    @_key_state = key_state
    @_links = []
    @_next_seqno = 1
    @_next_payload_hash = null
    @_unrevoked_links = {}
    @_valid_sibkeys = {}
    @_sibkey_order = [eldest_kid]
    # Eldest key starts out valid, but will be checked later for ownership.
    @_valid_sibkeys[eldest_kid] = true
    @_valid_subkeys = {}
    @_subkey_order = []
    @_eldest_key_delegated = false
    @_eldest_key_verified = false
    @_kid_to_etime_seconds = {}
    @_update_kid_pgp_etime { kid: eldest_kid }

  # Return the list of links in the current subchain which have not been
  # revoked.
  get_links : () ->
    return (link for link in @_links when link.sig_id of @_unrevoked_links)

  # Return the list of sibkey KIDs which aren't revoked or expired.
  get_sibkeys : ({now}) ->
    now = now or current_time_seconds()
    ret = []
    for kid in @_sibkey_order
      etime = @_kid_to_etime_seconds[kid]
      expired = (etime? and now > etime)
      if @_valid_sibkeys[kid] and not expired
        ret.push @_key_state.get_key_manager kid
    ret

  # Return the list of subkey KIDs which aren't revoked or expired.
  get_subkeys : ({now}) ->
    now = now or current_time_seconds()
    ret = []
    for kid in @_subkey_order
      etime = @_kid_to_etime_seconds[kid]
      expired = (etime? and now > etime)
      if @_valid_subkeys[kid] and not expired
        ret.push @_key_state.get_key_manager kid
    ret

  _add_new_link : ({sig_blob, sig_cache, log}, cb) ->
    esc = make_esc cb, "SigChain._add_new_link"

    # This constructor checks that the link is internally consistent: its
    # signature is valid and belongs to the key it claims, and the same for any
    # reverse sigs.
    await ChainLink.parse {sig_blob, key_state: @_key_state, sig_cache}, esc defer link
    log "| libkeybase: chain link parsed, type '#{link.payload.body.type}'"

    # Make sure the link belongs in this chain (right username and uid) and at
    # this particular point in the chain (right seqno and prev hash).
    await @_check_link_belongs_here {link}, esc defer()

    # Now check if this link's eldest key is the one we're looking for. If not,
    # this link belongs to a different subchain.
    if link.eldest_kid isnt @_eldest_kid
      if @_links.length == 0
        # This link is in an old subchain. Skip to the next link.
        log "| libkeybase: link not in the current subchain -- skipping ahead"
        cb null
        return
      else
        # There's another subchain AFTER the one we're looking for. This should
        # never happen -- until we build some sort of history-inspecting
        # feature in the future.
        cb new E.NotLatestSubchainError("Found a later subchain with eldest kid #{link.eldest_kid}")
        return

    # Finally, make sure that the key that signed this link was actually valid
    # at the time the link was signed.
    await @_check_key_is_valid {link}, esc defer()
    log "| libkeybase: signing key is valid (#{link.kid})"

    # This link is valid and part of the current subchain. Update all the
    # relevant metadata.
    @_links.push(link)
    @_unrevoked_links[link.sig_id] = link
    if link.kid == @_eldest_kid
      @_eldest_key_verified = true
    await @_delegate_keys {link, log}, esc defer()
    await @_revoke_keys_and_sigs {link, log}, esc defer()

    cb null

  _check_link_belongs_here : ({link}, cb) ->
    err = null
    if link.uid isnt @_uid
      err = new E.WrongUidError(
        "Link doesn't refer to the right uid,
        expected: #{link.uid} got: #{@_uid}")
    else if link.username.toLowerCase() isnt @_username.toLowerCase()
      err = new E.WrongUsernameError(
        "Link doesn't refer to the right username,
        expected: #{link.username} got: #{@_username}")
    else if link.seqno isnt @_next_seqno
      err = new E.WrongSeqnoError(
        "Link sequence number is wrong, expected:
        #{@_next_seqno} got: #{link.seqno}")
    else if @_next_payload_hash? and link.prev isnt @_next_payload_hash
      err = new E.WrongPrevError(
        "Previous payload hash doesn't match,
        expected: #{@_next_payload_hash} got: #{link.prev}")
    @_next_seqno++
    @_next_payload_hash = link.payload_hash
    cb err

  _check_key_is_valid : ({link}, cb) ->
    err = null
    if link.kid not of @_valid_sibkeys
      err = new E.InvalidSibkeyError("not a valid sibkey: #{link.kid}, valid sibkeys:
                                      #{JSON.stringify(kid for kid of @_valid_sibkeys)}")
    else if link.ctime_seconds > @_kid_to_etime_seconds[link.kid]
      err = new E.ExpiredSibkeyError "expired sibkey: #{link.kid}"
    cb err

  _delegate_keys : ({link, log}, cb) ->
    esc = make_esc cb, 'SigChain._delegate_keys'
    # The eldest key is valid from the beginning, but it might not get an etime
    # until the first link (unless it has an internal PGP etime).
    if link.kid is @_eldest_kid and not @_eldest_key_delegated
      @_update_kid_etime { kid: @_eldest_kid, etime_seconds: link.etime_seconds }
      if link.signing_key_hash?
        await @_key_state.set_key_hash {kid: @_eldest_kid, hash: link.signing_key_hash}, esc defer()
      @_eldest_key_delegated = true
    if link.sibkey_delegation?
      @_valid_sibkeys[link.sibkey_delegation] = true
      if link.sibkey_hash?
        await @_key_state.set_key_hash {kid: link.sibkey_delegation, hash: link.sibkey_hash}, esc defer()
      @_sibkey_order.push(link.sibkey_delegation)
      @_update_kid_etime { kid: link.sibkey_delegation, etime_seconds: link.etime_seconds }
      @_update_kid_pgp_etime { kid: link.sibkey_delegation }
      log "| libkeybase: delegating sibkey #{link.sibkey_delegation}"
    if link.subkey_delegation?
      @_valid_subkeys[link.subkey_delegation] = true
      @_subkey_order.push(link.subkey_delegation)
      @_update_kid_etime { kid: link.subkey_delegation, etime_seconds: link.etime_seconds }
      # Subkeys are always NaCl, never PGP.
    if link.pgp_update_kid? and link.pgp_update_hash? and @_valid_sibkeys[link.pgp_update_kid]?
      await @_key_state.set_key_hash {kid: link.pgp_update_kid, hash: link.pgp_update_hash}, esc defer()
    cb()

  _update_kid_pgp_etime : ({kid}) ->
    # PGP keys have an internal etime, which could be sooner than their link
    # etime. If so, that's what we'll use.
    key_manager = @_key_state.get_key_manager kid
    lifespan = key_manager?.primary?.lifespan
    if lifespan?.expire_in?
      etime_seconds = lifespan.generated + lifespan.expire_in
      @_update_kid_etime {kid, etime_seconds}

  _update_kid_etime : ({kid, etime_seconds}) ->
    # PGP keys can have two different etimes: the expiration time of their
    # delegating chain link and the internal expiration time recorded by PGP.
    # We believe the more restrictive of the two.
    if not @_kid_to_etime_seconds[kid]?
      @_kid_to_etime_seconds[kid] = etime_seconds
    else
      @_kid_to_etime_seconds[kid] = Math.min(etime_seconds, @_kid_to_etime_seconds[kid])

  _revoke_keys_and_sigs : ({link, log}, cb) ->
    # Handle direct sibkey revocations.
    for kid in link.key_revocations
      if kid of @_valid_sibkeys
        log "| libkeybase: revoking sibkey #{kid}"
        delete @_valid_sibkeys[kid]
      if kid of @_valid_subkeys
        delete @_valid_subkeys[kid]

    # Handle revocations of an entire link.
    for sig_id in link.sig_revocations
      if sig_id of @_unrevoked_links
        revoked_link = @_unrevoked_links[sig_id]
        delete @_unrevoked_links[sig_id]
        # Keys delegated by the revoked link are implicitly revoked as well.
        revoked_sibkey = revoked_link.sibkey_delegation
        if revoked_sibkey? and revoked_sibkey of @_valid_sibkeys
          log "| libkeybase: revoking sibkey #{revoked_sibkey} from sig #{sig_id}"
          delete @_valid_sibkeys[revoked_sibkey]
        revoked_subkey = revoked_link.subkey_delegation
        if revoked_subkey? and revoked_subkey of @_valid_subkeys
          delete @_valid_subkeys[revoked_subkey]
    cb()

  _enforce_eldest_key_ownership : ({}, cb) ->
    # It's important that users actually *prove* they own their eldest key,
    # rather than just claiming someone else's key as their own. The server
    # normally enforces this, and here we check the server's work. Proof can
    # happen in one of two ways: either the eldest key signs a link in the
    # sigchain (thereby referencing the username in the signature payload), or
    # the eldest key is a PGP key that self-signs its own identity.
    esc = make_esc cb, "SigChain._enforce_eldest_key_ownership"
    if @_eldest_key_verified
      # There was at least one chain link signed by the eldest key.
      cb null
      return
    # No chain link signed by the eldest key. Check PGP self sig.
    eldest_km = @_key_state.get_key_manager @_eldest_kid
    if not eldest_km?
      # Server-reported eldest key is simply missing.
      await athrow (new E.NonexistentKidError "no key for eldest kid #{@_eldest_kid}"), esc defer()
    userids = eldest_km.get_userids_mark_primary()
    if not userids?
      # Server-reported key doesn't self-sign any identities (probably because
      # it's a NaCl key and not a PGP key).
      await athrow (new E.KeyOwnershipError "key #{@_eldest_kid} is not self-signing"), esc defer()
    expected_email = @_username + "@keybase.io"
    for identity in userids
      if identity.get_email() == expected_email
        # Found a matching identity. This key is good.
        cb null
        return
    # No matching identity found.
    await athrow (new E.KeyOwnershipError "key #{@_eldest_kid} is not owned by #{expected_email}"), esc defer()

error_names = [
  "BAD_LINK_FORMAT"
  "EXPIRED_SIBKEY"
  "FINGERPRINT_MISMATCH"
  "INVALID_SIBKEY"
  "KEY_OWNERSHIP"
  "KID_MISMATCH"
  "NO_KEY_WITH_THIS_HASH"
  "NONEXISTENT_KID"
  "NOT_LATEST_SUBCHAIN"
  "REVERSE_SIG_VERIFY_FAILED"
  "VERIFY_FAILED"
  "WRONG_UID"
  "WRONG_USERNAME"
  "WRONG_SEQNO"
  "WRONG_PREV"
]

# make_errors() needs its input to be a map
errors_map = {}
for name in error_names
  errors_map[name] = ""
exports.E = E = ie.make_errors errors_map

current_time_seconds = () ->
  Math.floor(new Date().getTime() / 1000)

# Stupid coverage hack. If this breaks just delete it please, and I'm so sorry.
__iced_k_noop()
