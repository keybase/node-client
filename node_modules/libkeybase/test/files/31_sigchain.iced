{make_esc} = require 'iced-error'
fs = require('fs')
node_sigchain = require('../..')
C = require('../..').constants
execSync = require('child_process').execSync
fs = require('fs')
path = require('path')
tv = require 'keybase-test-vectors'

#====================================================

exports.test_eldest_key_required = (T, cb) ->
  # Make sure that if we forget to pass eldest key to SigChain.replay, that's
  # an error. Otherwise we could get confisingly empty results.
  esc = make_esc cb, "test_eldest_key_required"
  {chain, keys, username, uid} = tv.chain_test_inputs["ralph_chain.json"]
  await node_sigchain.ParsedKeys.parse {key_bundles: keys}, esc defer parsed_keys
  await node_sigchain.SigChain.replay {
    sig_blobs: chain
    parsed_keys
    uid
    username
    # OOPS! Forgot the eldest_kid!
  }, defer err, sigchain
  T.assert err, "Forgetting to pass the eldest_kid should fail the replay!"
  cb()

exports.test_chain_link_format = (T, cb) ->
  # The Go implementation is strict about details like UID length. This
  # implementation was lenient, so we ended up creating some test cases that
  # were unusable with Go. After fixing the test cases, we added
  # check_link_payload_format() to make sure we don't miss this again. This
  # test just provides coverage for that method. It's not necessarily a failure
  # that other implementations should reproduce.
  bad_uid_payload =
    body:
      key:
        uid: "wronglen"
  await node_sigchain.check_link_payload_format {payload: bad_uid_payload}, defer err
  T.assert err?, "short uid should fail"
  if err?
    T.assert err.code == node_sigchain.E.code.BAD_LINK_FORMAT, "wrong error type"
  cb()

exports.test_check_buffers_equal = (T, cb) ->
  # Test coverage for check_buffers_equal, which can never fail under normal
  # circumstances.
  await node_sigchain.check_buffers_equal (new Buffer('0')), (new Buffer('1')), defer err
  T.assert err?
  cb()

exports.test_sig_cache = (T, cb) ->
  # We accept a sig_cache parameter to skip verifying signatures that we've
  # verified before. Exercise that code. (Piggybacking on that, use a fake log
  # to exercise that code too.)
  esc = make_esc cb, "test_sig_cache"
  {chain, keys, username, uid, label_kids} = tv.chain_test_inputs["ralph_chain.json"]

  # Create a fake sig_cache.
  store = {}
  sig_cache =
    get: ({sig_id}, cb) ->
      cb null, store[sig_id]
    put: ({sig_id, payload_buffer}, cb) ->
      T.assert(sig_id? and payload_buffer?,
               "Trying to cache something bad: #{sig_id}, #{payload_buffer}")
      store[sig_id] = payload_buffer
      cb null

  # Create a fake log.
  log = (() -> null)

  # Zero the unbox counter (in case other tests have run earlier).
  node_sigchain.debug.unbox_count = 0

  # Replay the sigchain the first time.
  await node_sigchain.ParsedKeys.parse {key_bundles: keys}, esc defer parsed_keys
  await node_sigchain.SigChain.replay {
    sig_blobs: chain
    parsed_keys
    sig_cache
    uid
    username
    eldest_kid: label_kids.second_eldest
    log
  }, esc defer sigchain

  # Confirm that there's stuff in the cache.
  T.equal chain.length, Object.keys(store).length, "All the chain link sigs should be cached."

  # Assert the new value of the unbox counter.
  T.equal chain.length, node_sigchain.debug.unbox_count, "unboxed ralph's links"

  # Replay it again with the full cache to exercise the cache hit code path.
  await node_sigchain.ParsedKeys.parse {key_bundles: keys}, esc defer parsed_keys
  await node_sigchain.SigChain.replay {
    sig_blobs: chain
    parsed_keys
    sig_cache
    uid
    username
    eldest_kid: label_kids.second_eldest
  }, esc defer sigchain

  # Confirm the cache hasn't grown.
  T.equal chain.length, Object.keys(store).length, "Cache should be the same size it was before."

  # Assert the unbox counter hasn't moved.
  T.equal chain.length, node_sigchain.debug.unbox_count, "no further unboxing"

  cb()

exports.test_all_sigchain_tests = (T, cb) ->
  # This runs all the tests described in tests.json, which included many
  # example chains with both success parameters and expected failures.
  for test_name, body of tv.chain_tests.tests
    args = {T}
    for key, val of body
        args[key] = val
    T.waypoint test_name
    await do_sigchain_test args, defer err
    T.assert not err?, "Error in sigchain test '#{test_name}': #{err}"
  cb()

do_sigchain_test = ({T, input, err_type, len, sibkeys, subkeys, eldest}, cb) ->
  esc = make_esc cb, "do_sigchain_test"
  input_blob = tv.chain_test_inputs[input]
  {chain, keys, username, uid} = input_blob
  await node_sigchain.ParsedKeys.parse {key_bundles: keys}, esc defer parsed_keys, default_eldest
  if not eldest?
    # By default, use the first key as the eldest.
    eldest_kid = default_eldest
  else
    eldest_kid = input_blob.label_kids[eldest]
  await node_sigchain.SigChain.replay {
    sig_blobs: chain
    parsed_keys
    uid
    username
    eldest_kid
  }, defer err, sigchain
  if err?
    if not err_type? or err_type != node_sigchain.E.name[err.code]
      # Not an error we expected.
      cb err
      return
    else
      # The error we were looking for!
      cb null
      return
  else if err_type?
    # We expected an error, and didn't get one!
    cb new Error "Expected error of type #{err_type}"
    return
  # No error.
  # Check the number of unrevoked links.
  links = sigchain.get_links()
  if len?
    T.assert links.length == len, "Expected exactly #{len} links, got #{links.length}"
  check_sibkey_and_subkey_count {T, sigchain, parsed_keys, eldest_kid, sibkeys, subkeys}
  cb()

check_sibkey_and_subkey_count = ({T, sigchain, parsed_keys, eldest_kid, sibkeys, subkeys}) ->
  # Don't use the current time for tests, because eventually that will cause
  # keys to expire and tests to break.
  now = get_current_time_for_test { sigchain, parsed_keys }
  far_future = now + 100 * 365 * 24 * 60 * 60  # 100 years from now

  # Check the number of unrevoked/unexpired sibkeys.
  sibkeys_list = sigchain.get_sibkeys {now}
  if sibkeys?
    T.assert sibkeys_list.length == sibkeys, "Expected exactly #{sibkeys} sibkeys, got #{sibkeys_list.length}"
  if sigchain.get_links().length > 0
    # The eldest key might not expire if there are no links. Just skip this part of the test.
    T.assert sigchain.get_sibkeys({now: far_future}).length == 0, "Expected no sibkeys in the far future."

  # Check the number of unrevoked/unexpired subkeys.
  subkeys_list = sigchain.get_subkeys {now}
  if subkeys?
    T.assert subkeys_list.length == subkeys, "Expected exactly #{subkeys} subkeys, got #{subkeys_list.length}"
  T.assert sigchain.get_subkeys({now: far_future}).length == 0, "Expected no subkeys in the far future."

  # Get keys with the default time parameter (real now), just to make sure
  # nothing blows up (and to improve coverage :-D)
  sigchain.get_sibkeys {}
  sigchain.get_subkeys {}

get_current_time_for_test = ({sigchain, parsed_keys}) ->
  # Pick a time that's later than the ctime of all links and PGP keys.
  t_seconds = 0
  for link in sigchain.get_links()
    t_seconds = Math.max(t_seconds, link.ctime_seconds)
  for kid, km of parsed_keys.key_managers
    if km.primary?.lifespan?.generated?
      t_seconds = Math.max(t_seconds, km.primary.lifespan.generated)
  return t_seconds
