{athrow, a_json_parse} = require('iced-utils').util
{make_esc} = require 'iced-error'
kbpgp = require('kbpgp')
proofs = require('keybase-proofs')
ie = require('iced-error')

UID_LEN = 32
exports.SIG_ID_SUFFIX = SIG_ID_SUFFIX = "0f"

exports.ParsedKeys = class ParsedKeys
  @parse : ({bundles_list}, cb) ->
    # We only take key bundles from the server, either hex NaCl public keys, or
    # ascii-armored PGP public key strings. We compute the KIDs and
    # fingerprints ourselves, because we don't trust the server to do it for
    # us.
    esc = make_esc cb, "ParsedKeys.parse"
    key_managers = {}
    pgp_to_kid = {}
    kid_to_pgp = {}
    kids_in_order = []  # for testing
    for bundle in bundles_list
      await kbpgp.ukm.import_armored_public {armored: bundle}, esc defer key_manager
      kid = key_manager.get_ekid()
      kid_str = kid.toString "hex"
      key_managers[kid_str] = key_manager
      kids_in_order.push(kid_str)
      fingerprint = key_manager.get_pgp_fingerprint()
      if fingerprint?
        # Only PGP keys have a non-null fingerprint.
        fingerprint_str = fingerprint.toString "hex"
        pgp_to_kid[fingerprint_str] = kid_str
        kid_to_pgp[kid_str] = fingerprint_str
    parsed_keys = new ParsedKeys {key_managers, pgp_to_kid, kid_to_pgp, kids_in_order}
    cb null, parsed_keys

  constructor : ({@key_managers, @pgp_to_kid, @kid_to_pgp, @kids_in_order}) ->


class ChainLink
  @parse : ({sig_blob, parsed_keys, sig_cache}, cb) ->
    esc = make_esc cb, "ChainLink.parse"
    # Unbox the signed payload. PGP key expiration is checked automatically
    # during unbox, using the ctime of the chainlink.
    await @_unbox_payload {sig_blob, parsed_keys, sig_cache}, esc defer payload, sig_id, payload_hash
    # Check internal details of the payload, like uid length.
    await check_link_payload_format {payload}, esc defer()
    # Make sure the KID and ctime from the blob match the payload, and that any
    # payload PGP fingerprint also matches the KID.
    await @_check_payload_against_blob {sig_blob, payload, parsed_keys}, esc defer()
    # Check any reverse signatures.
    await @_check_reverse_signatures {payload, parsed_keys}, esc defer()
    # The constructor takes care of all the payload parsing that isn't failable.
    cb null, new ChainLink {kid: sig_blob.kid, sig_id, payload, payload_hash}

  @_unbox_payload : ({sig_blob, parsed_keys, sig_cache}, cb) ->
    esc = make_esc cb, "ChainLink._unbox_payload"
    # Get the ctime and the KID directly from the server blob. These are the
    # only pieces of data that we don't get from the unboxed sig payload,
    # because we need them to do the uboxing. We check them against what's in
    # the box later, and freak out of there's a difference.
    kid = sig_blob.kid
    ctime_seconds = sig_blob.ctime
    # Get the key_manager and sig_eng we need from the ParsedKeys object.
    key_manager = parsed_keys.key_managers[kid]
    if not key_manager?
      await athrow (new E.NonexistentKidError "link signed by nonexistent kid #{kid}"), esc defer()
    sig_eng = key_manager.make_sig_eng()
    # Compute the sig_id. We return this, but we also use it to check whether
    # this sig is in the sig_cache, meaning it's already been verified.
    await sig_eng.get_body {armored: sig_blob.sig}, esc defer sig_body
    sig_id = kbpgp.hash.SHA256(sig_body).toString("hex") + SIG_ID_SUFFIX
    # Check whether the sig is cached. If so, get the payload from cache.
    if sig_cache?
      await sig_cache.get {sig_id}, esc defer payload_buffer
    # If we didn't get the payload from cache, unbox it for real.
    if not payload_buffer?
      did_unbox = true
      await key_manager.make_sig_eng().unbox(
        sig_blob.sig,
        defer(err, payload_buffer),
        {now: ctime_seconds})
      if err?
        await athrow (new E.VerifyFailedError err.message), esc defer()
    # Compute the payload_hash.
    payload_hash = kbpgp.hash.SHA256(payload_buffer).toString("hex")
    # Parse the payload.
    payload_json = payload_buffer.toString('utf8')
    await a_json_parse payload_json, esc defer payload
    # Success!
    if sig_cache? and did_unbox
      await sig_cache.put {sig_id, payload_buffer}, esc defer()
    cb null, payload, sig_id, payload_hash

  @_check_payload_against_blob : ({sig_blob, payload, parsed_keys}, cb) ->
    # Here's where we check the data we relied on in @_unbox_payload().
    signing_kid = sig_blob.kid
    signing_ctime = sig_blob.ctime
    payload_kid = payload.body.key.kid
    payload_fingerprint = payload.body.key.fingerprint
    payload_ctime = payload.ctime
    err = null
    if payload_kid? and payload_kid isnt signing_kid
      err = new E.KidMismatchError "signing kid (#{signing_kid}) and payload kid (#{payload_kid}) mismatch"
    else if payload_fingerprint? and payload_fingerprint isnt parsed_keys.kid_to_pgp[signing_kid]
      err = new E.FingerprintMismatchError "signing kid (#{signing_kid}) and payload fingerprint (#{payload_fingerprint}) mismatch"
    else if payload_ctime isnt signing_ctime
      err = new E.CtimeMismatchError "payload ctime (#{payload_ctime}) doesn't match signing ctime (#{signing_ctime})"
    cb err

  @_check_reverse_signatures : ({payload, parsed_keys}, cb) ->
    esc = make_esc cb, "ChainLink._check_reverse_signatures"
    if not payload.body.sibkey?
      cb null
      return
    kid = payload.body.sibkey.kid
    key_manager = parsed_keys.key_managers[kid]
    if not key_manager?
      await athrow (new E.NonexistentKidError "link reverse-signed by nonexistent kid #{kid}"), esc defer()
    sibkey_proof = new proofs.Sibkey {}
    await sibkey_proof.reverse_sig_check {json: payload, subkm: key_manager}, defer err
    if err?
      await athrow (new E.ReverseSigVerifyFailedError err.message), esc defer()
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

    @sibkey_delegation = @payload.body.sibkey?.kid
    @subkey_delegation = @payload.body.subkey?.kid

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


exports.SigChain = class SigChain

  # The replay() method is the main interface for all callers. It checks all of
  # the user's signatures and returns a SigChain object representing their
  # current state.
  #
  # @param {[string]} sig_blobs The parsed JSON signatures list returned from
  #     the server's sig/get.json endpoint.
  # @param {ParsedKeys} parsed_keys The collection of the user's keys. This is
  #     usually obtained from the all_bundles list given by user/lookup.json,
  #     given to ParsedKeys.parse().
  # @param {object} sig_cache An object with two methods: get({sig_id}, cb) and
  #     put({sig_id, payload_buffer}, cb), which caches the payloads of
  #     previously verified signatures. This parameter can be null, in which
  #     case all signatures will be checked.
  # @param {string} uid Used only to check that the sigchain belongs to the
  #     right user.
  # @param {string} username As with uid, used for confirming ownership.
  # @param {string} eldest_kid The full (i.e. with-prefix) KID of the user's
  #     current eldest key. This is used to determine the latest subchain.
  @replay : ({sig_blobs, parsed_keys, sig_cache, uid, username, eldest_kid}, cb) ->
    esc = make_esc cb, "SigChain.replay"
    # Forgetting the eldest KID would silently give you an empty sigchain. Prevent this.
    if not eldest_kid?
      await athrow (new Error "eldest_kid parameter is required"), esc defer()
    # Initialize the SigChain.
    sigchain = new SigChain {uid, username, eldest_kid, parsed_keys}
    # Build the chain link by link, checking consistency all the way through.
    for sig_blob in sig_blobs
      await sigchain._add_new_link {sig_blob, parsed_keys, sig_cache}, esc defer()
    # After the chain is finished, make sure we've proven ownership of the
    # eldest key in some way.
    await sigchain._enforce_eldest_key_ownership {parsed_keys}, esc defer()
    cb null, sigchain

  # NOTE: Don't call the constructor directly. Use SigChain.replay().
  constructor : ({uid, username, eldest_kid, parsed_keys}) ->
    @_uid = uid
    @_username = username
    @_eldest_kid = eldest_kid
    @_links = []
    @_next_seqno = 1
    @_next_payload_hash = null
    @_unrevoked_links = {}
    @_valid_sibkeys = {}
    # Eldest key starts out valid, but will be checked later for ownership.
    @_valid_sibkeys[eldest_kid] = true
    @_valid_subkeys = {}
    @_eldest_key_delegated = false
    @_eldest_key_verified = false
    @_kid_to_etime_seconds = {}
    # Get all the PGP key etimes, which could be sooner than link etimes.
    for kid, km of parsed_keys.key_managers
      if km.primary?.lifespan?
        etime_seconds = km.primary.lifespan.generated + km.primary.lifespan.expire_in
        @_update_kid_etime {kid, etime_seconds}

  # Return the list of links in the current subchain which have not been
  # revoked.
  get_links : () ->
    return (link for link in @_links when link.sig_id of @_unrevoked_links)

  # Return the list of sibkey KIDs which aren't revoked or expired.
  get_sibkeys : ({now}) ->
    now = now or current_time_seconds()
    return (kid for kid of @_valid_sibkeys when @_kid_to_etime_seconds[kid] > now)

  # Return the list of subkey KIDs which aren't revoked or expired.
  get_subkeys : ({now}) ->
    now = now or current_time_seconds()
    return (kid for kid of @_valid_subkeys when @_kid_to_etime_seconds[kid] > now)

  _add_new_link : ({sig_blob, parsed_keys, sig_cache}, cb) ->
    esc = make_esc cb, "SigChain._add_new_link"

    # This constructor checks that the link is internally consistent: its
    # signature is valid and belongs to the key it claims, and the same for any
    # reverse sigs.
    await ChainLink.parse {sig_blob, parsed_keys, sig_cache}, esc defer link

    # Make sure the link belongs in this chain (right username and uid) and at
    # this particular point in the chain (right seqno and prev hash).
    await @_check_link_belongs_here {link}, esc defer()

    # Now check if this link's eldest key is the one we're looking for. If not,
    # this link belongs to a different subchain.
    if link.eldest_kid isnt @_eldest_kid
      if @_links.length == 0
        # This link is in an old subchain. Skip to the next link.
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

    # This link is valid and part of the current subchain. Update all the
    # relevant metadata.
    @_links.push(link)
    @_unrevoked_links[link.sig_id] = link
    if link.kid == @_eldest_kid
      @_eldest_key_verified = true
    await @_delegate_keys {link}, esc defer()
    await @_revoke_keys_and_sigs {link}, esc defer()

    cb null

  _check_link_belongs_here : ({link}, cb) ->
    err = null
    if link.uid isnt @_uid
      err = new E.WrongUidError(
        "Link doesn't refer to the right uid,
        expected: #{link.uid} got: #{@_uid}")
    else if link.username isnt @_username
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

  _delegate_keys : ({link}, cb) ->
    # The eldest key is valid from the beginning, but it might not get an etime
    # until the first link (unless it has an internal PGP etime).
    if link.kid is @_eldest_kid and not @_eldest_key_delegated
      @_update_kid_etime { kid: @_eldest_kid, etime_seconds: link.etime_seconds }
      @_eldest_key_delegated = true
    if link.sibkey_delegation?
      @_valid_sibkeys[link.sibkey_delegation] = true
      @_update_kid_etime { kid: link.sibkey_delegation, etime_seconds: link.etime_seconds }
    if link.subkey_delegation?
      @_valid_subkeys[link.subkey_delegation] = true
      @_update_kid_etime { kid: link.subkey_delegation, etime_seconds: link.etime_seconds }
    cb()

  _update_kid_etime : ({kid, etime_seconds}) ->
    # PGP keys can have two different etimes: the expiration time of their
    # delegating chain link and the internal expiration time recorded by PGP.
    # We believe the more restrictive of the two.
    if not @_kid_to_etime_seconds[kid]?
      @_kid_to_etime_seconds[kid] = etime_seconds
    else
      @_kid_to_etime_seconds[kid] = Math.min(etime_seconds, @_kid_to_etime_seconds[kid])

  _revoke_keys_and_sigs : ({link}, cb) ->
    # Handle direct sibkey revocations.
    for kid in link.key_revocations
      if kid of @_valid_sibkeys
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
          delete @_valid_sibkeys[revoked_sibkey]
        revoked_subkey = revoked_link.subkey_delegation
        if revoked_subkey? and revoked_subkey of @_valid_subkeys
          delete @_valid_subkeys[revoked_subkey]
    cb()

  _enforce_eldest_key_ownership : ({parsed_keys}, cb) ->
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
    eldest_km = parsed_keys.key_managers[@_eldest_kid]
    if not eldest_km?
      # Server-reported eldest key is simply missing.
      await athrow (new E.NonexistentKidError "no key for eldest kid #{@_eldest_kid}"), esc defer()
    if not eldest_km.userids?
      # Server-reported key doesn't self-sign any identities (probably because
      # it's a NaCl key and not a PGP key).
      await athrow (new E.KeyOwnershipError "key #{@_eldest_kid} is not self-signing"), esc defer()
    expected_email = @_username + "@keybase.io"
    for identity in eldest_km.userids
      if identity.get_email() == expected_email
        # Found a matching identity. This key is good.
        cb null
        return
    # No matching identity found.
    await athrow (new E.KeyOwnershipError "key #{@_eldest_kid} is not owned by #{expected_email}"), esc defer()

error_names = [
  "BAD_LINK_FORMAT"
  "CTIME_MISMATCH"
  "EXPIRED_SIBKEY"
  "FINGERPRINT_MISMATCH"
  "INVALID_SIBKEY"
  "KEY_OWNERSHIP"
  "KID_MISMATCH"
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
