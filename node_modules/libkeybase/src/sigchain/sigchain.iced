{bufeq_secure,athrow, a_json_parse} = require('iced-utils').util
{make_esc} = require 'iced-error'
kbpgp = require('kbpgp')
proofs = require('keybase-proofs')
ie = require('iced-error')
{trim} = require('pgp-utils').util

UID_LEN = 32
exports.SIG_ID_SUFFIX = SIG_ID_SUFFIX = "0f"

strip_final_newline = (buf) ->
  s = buf.toString('utf8')
  if s[-1...] is "\n" then new Buffer s[0...-1], "utf8"
  else buf

# On 15 Sep 2015, a day that will live in infamy, some users made bad
# sigchain additions due to a code error that was stripping out
# whitespace from json payloads, writing those payloads to the DB, and then
# offering those payloads back out for subsequent signatures. We address that
# issue here by subtracting that dropped newline out right before we hash.
# We should potentially have a whitelist here for sigids that are affected:
bad_whitespace_sig_ids = {
  "595a73fc649c2c8ccc1aa79384e0b3e7ab3049d8df838f75ef0edbcb5bbc42990f" : true
  "e256078702afd7a15a24681259935b48342a49840ab6a90291b300961669790f0f" : true
  "30831001edee5e01c3b5f5850043f9ef7749a1ed8624dc703ae0922e1d0f16dd0f" : true
  "88e6c581dbccbf390559bcb30ca21548ba0ec4861ec2d666217bd4ed4a4a8c3f0f" : true
  "4db0fe3973b3a666c7830fcb39d93282f8bc414eca1d535033a5cc625eabda0c0f" : true
  "9ba23a9a1796fb22b3c938f1edf5aba4ca5be7959d9151895eb6aa7a8d8ade420f" : true
  "df0005f6c61bd6efd2867b320013800781f7f047e83fd44d484c2cb2616f019f0f" : true
  "a32692af33e559e00a40aa3bb4004744d2c1083112468ed1c8040eaacd15c6eb0f" : true
  "3e61901f50508aba72f12740fda2be488571afc51d718d845e339e5d1d1b531d0f" : true
  "de43758b653b3383aca640a96c7890458eadd35242e8f8531f29b606890a14ea0f" : true
  "b9ee3b46c97d48742a73e35494d3a373602460609e3c6c54a553fc4d83b659e40f" : true
  "0ff29c1d036c3f4841f3f485e28d77351abb3eeeb52d2f8d802fd15e383d9a5f0f" : true
  "eb1a13c6b6e42bb7470e222b51d36144a25ffc4fbc0b32e9a1ec11f059001bc80f" : true
  "9c189d6d644bad9596f78519d870a685624f813afc1d0e49155073d3b0521f970f" : true
  "aea7c8f7726871714e777ac730e77e1905a38e9587f9504b739ff9b77ef2d5cc0f" : true
  "ac6e225b8324c1fcbe814382e198495bea801dfeb56cb22b9e89066cc52ab03b0f" : true
  "3034e8b7d75861fc28a478b4992a8592b5478d4cbc7b87150d0b59573d731d870f" : true
  "140f1b7b7ba32f34ad6302d0ed78692cf1564760d78c082965dc3b8b5f7e27f10f" : true
  "833f27edcf54cc489795df1dc7d9f0cbea8253e1b84f5e82749a7a2a4ffc295c0f" : true
  "110a64513b4188eca2af6406a8a6dbf278dfce324b8879b5cb67e8626ff2af180f" : true
  "3042dbe45383b0c2eafe13a73da35c4e721be026d7908dfcef6eb121d95b75b10f" : true
  "50ba350ddc388f7c6fdba032a7d283e4caa0ca656f92f69257213222dd7deeaf0f" : true
  "803854b4074d668e1761ee9c533c0fc576bd0404cf26ff7545e14512f3b9002f0f" : true
  "2e08f0b9566e15fa1f9e67b236e5385cdb38d57ff51d7ab3e568532867c9f8890f" : true
  "cb97f4b62f2e817e8db8c6193440214ad20f906571e4851db186869f0b4c0e310f" : true
  "a5c4a30d1eaaf752df424bf813c5a907a5cf94fd371e280d39e0a3d078310fba0f" : true
  "c7d26afbc1957ecca890d8d9001a9cc4863490161720ad76a2aedeb8c2d50df70f" : true
  "b385c0c76d790aba156ff68fd571171fc7cb85f75e7fc9d1561d7960d8875acb0f" : true
  "47d349b8bb3c8457449390ca2ed5e489a70ad511ab3edb4c7f0af27eed8c65d30f" : true
  "2785b24acd6869e1e7d38a91793af549f3c35cd0729127d200b66f8c0ffba59b0f" : true
  "503df567f98cf5910ba44cb95e157e656afe95d159a15c7df4e88ac6016c948f0f" : true
  "2892863758cdaf9796fb36e2466093762efda94e74eb51e3ab9d6bec54064b8a0f" : true
  "e1d60584995e677254f7d913b3f40060b5500241d6de0c5822ba1282acc5e08b0f" : true
  "031b506b705926ea962e59046bfe1720dcf72c85310502020e2ae836b294fcde0f" : true
  "1454fec21489f17a6d78927af1c9dca4209360c6ef6bfa569d8b62d32e668ea30f" : true
  "ba68052597a3782f64079d7d9ec821ea9785c0868e44b597a04c9cd8bf634c1e0f" : true
  "db8d59151b2f78c82c095c9545f1e4d39947a0c0bcc01b907e0ace14517d39970f" : true
  "e088beccfee26c5df39239023d1e4e0cbcd63fd50d0bdc4bf2c2ba25ef1a8fe40f" : true
  "8182f385c347fe57d3c46fe40e8df0e2d6cabdac38f490417b313050249be9dc0f" : true
  "2415e1c77b0815661452ea683e366c6d9dfd2008a7dbc907004c3a33e56cf6190f" : true
  "44847743878bd56f5cd74980475e8f4e95d0d6ec1dd8722fd7cfc7761698ec780f" : true
  "70c4026afec66312456b6820492b7936bff42b58ca7a035729462700677ef4190f" : true
  "7591a920a5050de28faad24b5fe3336f658b964e0e64464b70878bfcf04537420f" : true
  "10a45e10ff2585b03b9b5bc449cb1a7a44fbb7fcf25565286cb2d969ad9b89ae0f" : true
  "062e6799f211177023bc310fd6e4e28a8e2e18f972d9b037d24434a203aca7240f" : true
  "db9a0afaab297048be0d44ffd6d89a3eb6a003256426d7fd87a60ab59880f8160f" : true
  "58bf751ddd23065a820449701f8a1a0a46019e1c54612ea0867086dbd405589a0f" : true
  "062e6799f211177023bc310fd6e4e28a8e2e18f972d9b037d24434a203aca7240f" : true
  "10a45e10ff2585b03b9b5bc449cb1a7a44fbb7fcf25565286cb2d969ad9b89ae0f" : true
  "44847743878bd56f5cd74980475e8f4e95d0d6ec1dd8722fd7cfc7761698ec780f" : true
  "58bf751ddd23065a820449701f8a1a0a46019e1c54612ea0867086dbd405589a0f" : true
  "70c4026afec66312456b6820492b7936bff42b58ca7a035729462700677ef4190f" : true
  "7591a920a5050de28faad24b5fe3336f658b964e0e64464b70878bfcf04537420f" : true
  "db9a0afaab297048be0d44ffd6d89a3eb6a003256426d7fd87a60ab59880f8160f" : true
}

# We had an incident where a Go client using an old reverse-sig format got some
# links into a public chain. (Sorry Fred!) Skip reverse signature checking for
# this fixed set of links.
known_buggy_reverse_sigs = {
  "2a0da9730f049133ce728ba30de8c91b6658b7a375e82c4b3528d7ddb1a21f7a0f": true
  "eb5c7e7d3cf8370bed8ab55c0d8833ce9d74fd2c614cf2cd2d4c30feca4518fa0f": true
  "0f175ef0d3b57a9991db5deb30f2432a85bc05922bbe727016f3fb660863a1890f": true
  "48267f0e3484b2f97859829503e20c2f598529b42c1d840a8fc1eceda71458400f": true
};

# Some users (6) managed to reuse eldest keys after a sigchain reset, without
# using the "eldest" link type, before the server prohibited this. To clients,
# that means their chains don't appear to reset. We hardcode these cases.
hardcoded_resets = {
  "11111487aa193b9fafc92851176803af8ed005983cad1eaf5d6a49a459b8fffe0f": true
  "df0005f6c61bd6efd2867b320013800781f7f047e83fd44d484c2cb2616f019f0f": true
  "32eab86aa31796db3200f42f2553d330b8a68931544bbb98452a80ad2b0003d30f": true
  "5ed7a3356fd0f759a4498fc6fed1dca7f62611eb14f782a2a9cda1b836c58db50f": true
  "d5fe2c5e31958fe45a7f42b325375d5bd8916ef757f736a6faaa66a6b18bec780f": true
  "1e116e81bc08b915d9df93dc35c202a75ead36c479327cdf49a15f3768ac58f80f": true
}

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
      return
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
    # Check any reverse signatures. For links where we skip this step, we will
    # ignore their contents later.
    if not known_buggy_reverse_sigs[sig_id]
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

    # See comment above about bad whitespace sigs from 15 Sep 2015
    hash_input = if bad_whitespace_sig_ids[sig_id] then strip_final_newline verified_buffer
    else verified_buffer

    payload_hash = kbpgp.hash.SHA256(hash_input).toString("hex")

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
    @type = @payload.body.type

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
    sigchain = new SigChain {uid, username, eldest_kid, parsed_keys}
    # Build the chain link by link, checking consistency all the way through.
    for sig_blob in sig_blobs
      log "| libkeybase: replaying signature #{sig_blob.seqno}: #{sig_blob.sig_id}"
      await sigchain._add_new_link {sig_blob, sig_cache, log}, esc defer()
    # If the eldest kid of the current subchain doesn't match the eldest kid
    # we're looking for, that means we're on a new zero-length subchain.
    if eldest_kid isnt sigchain._current_subchain_eldest
      sigchain._reset_subchain(eldest_kid)
    # After the chain is finished, make sure we've proven ownership of the
    # eldest key in some way.
    await sigchain._enforce_eldest_key_ownership {}, esc defer()
    log "- libkeybase: replay finished"
    cb null, sigchain

  # NOTE: Don't call the constructor directly. Use SigChain.replay().
  constructor : ({uid, username, eldest_kid, parsed_keys}) ->
    @_uid = uid
    @_username = username
    @_eldest_kid = eldest_kid
    @_parsed_keys = parsed_keys
    @_next_seqno = 1
    @_next_payload_hash = null

    @_reset_subchain(null)

  _reset_subchain : (current_subchain_eldest) ->
    @_current_subchain = []
    @_current_subchain_eldest = current_subchain_eldest
    @_key_state = new KeyState {parsed_keys: @_parsed_keys}
    @_unrevoked_links = {}
    @_valid_sibkeys = {}
    @_valid_sibkeys[current_subchain_eldest] = true
    @_sibkey_order = [current_subchain_eldest]
    @_valid_subkeys = {}
    @_subkey_order = []
    @_kid_to_etime_seconds = {}
    @_update_kid_pgp_etime { kid: current_subchain_eldest }

  # Return the list of links in the current subchain which have not been
  # revoked.
  get_links : () ->
    return (link for link in @_current_subchain when link.sig_id of @_unrevoked_links)

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

    # Now see if we've hit a sigchain reset. That can happen for one of two
    # reasons:
    #   1) The eldest kid reported by this link (either explicitly or
    #      implicitly; see ChainLink.eldest_kid) is different from the one that
    #      came before it.
    #   2) This link is of the "eldest" type.
    # We *don't* short-circuit here though. Verifying past subchains just like
    # we verify the current one actually simplifies PGP full hash handling.
    # (Otherwise we'd have to figure out how to maintain the KeyState, or else
    # we wouldn't even be able to verify link signatures [correctly, without
    # resorting to key merging].)
    if (link.eldest_kid isnt @_current_subchain_eldest or
        link.type is "eldest" or
        hardcoded_resets[link.sig_id])
      log "| libkeybase: starting new subchain"
      @_reset_subchain(link.eldest_kid)

    # Links with known bad reverse sigs still have to have valid payload hashes
    # and seqnos, but their contents are ignored, and their signing keys might
    # not be valid sibkeys (because the delegating links of those sibkeys might
    # also have been bad). Short-circuit here for these links, after checking
    # the link position but before checking the validity of the signing key.
    if known_buggy_reverse_sigs[link.sig_id]
      cb null
      return

    # Finally, make sure that the key that signed this link was actually valid
    # at the time the link was signed.
    await @_check_key_is_valid {link}, esc defer()
    log "| libkeybase: signing key is valid (#{link.kid})"

    # This link is valid and part of the current subchain. Update all the
    # relevant metadata.
    @_current_subchain.push(link)
    @_unrevoked_links[link.sig_id] = link
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
    # If this is the first link in the subchain, it implicitly delegates the
    # eldest key.
    if @_current_subchain.length == 1
      log "| libkeybase: delegating eldest key #{link.kid}"
      await @_delegate_sibkey {
        kid: link.kid
        etime_seconds: link.etime_seconds
        full_hash: link.signing_key_hash
      }, esc defer()

    if link.sibkey_delegation?
      log "| libkeybase: delegating sibkey #{link.sibkey_delegation}"
      await @_delegate_sibkey {
        kid: link.sibkey_delegation
        etime_seconds: link.etime_seconds
        full_hash: link.sibkey_hash
      }, esc defer()

    if link.subkey_delegation?
      log "| libkeybase: delegating subkey #{link.subkey_delegation}"
      await @_delegate_subkey {
        kid: link.subkey_delegation
        etime_seconds: link.etime_seconds
      }, esc defer()

    # Handle pgp_update links.
    if link.pgp_update_kid? and link.pgp_update_hash? and @_valid_sibkeys[link.pgp_update_kid]?
      await @_key_state.set_key_hash {kid: link.pgp_update_kid, hash: link.pgp_update_hash}, esc defer()
    cb()

  _delegate_sibkey : ({kid, etime_seconds, full_hash}, cb) ->
    esc = make_esc cb, 'SigChain._delegate_sibkey'
    @_valid_sibkeys[kid] = true
    if kid not in @_sibkey_order
      @_sibkey_order.push kid
    @_update_kid_etime { kid, etime_seconds }
    @_update_kid_pgp_etime { kid }
    if full_hash?
      await @_key_state.set_key_hash {kid, hash: full_hash}, esc defer()
    cb null

  _delegate_subkey : ({kid, etime_seconds}, cb) ->
    esc = make_esc cb, 'SigChain._delegate_subkey'
    @_valid_subkeys[kid] = true
    if kid not in @_subkey_order
      @_subkey_order.push kid
    @_update_kid_etime { kid, etime_seconds }
    # Subkeys are always NaCl, never PGP. So no full hash or pgp_etime stuff.
    cb null

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
    if @_current_subchain.length > 0
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
