
{User} = require '../lib/user'
user = null
found = false
log = require '../../lib/log'
keypool = require '../lib/keypool'

exports.init = (T,cb) ->
  user = User.generate 'alice'
  await user.check_if_exists defer tmp
  found = tmp
  if found
    log.info "Found 'alice', won't try to remake her"
  else
    log.info "Alice wasn't found!"
  cb()

exports.generate = (T,cb) ->
  T.assert user, "a user came back"
  cb()

exports.init_user = (T,cb) ->
  if found
    await keypool.grab defer err, key
    T.no_error err
    T.assert key, "grabbing Alice's key from pool"
  else
    await user.init defer err
    T.no_error err
  cb()

exports.signup = (T,cb) ->
  unless found
    await user.signup defer err
    T.no_error err
  cb()

exports.failed_revoke = (T,cb) ->
  unless found
    await user.revoke_key defer err
    T.assert err, "We should fail to revoke a key that's not registered"
  cb()

exports.push_key = (T,cb) ->
  unless found
    await user.push_key defer err
    T.no_error err
  cb()

exports.write_pw = (T,cb) ->
  unless found
    await user.write_pw defer err
    T.no_error err
  cb()

exports.login_logout = (T,cb) ->
  await user.logout defer err
  T.no_error err
  await user.login defer err
  T.no_error err
  cb()

exports.prove_github = (T,cb) ->
  unless found
    await user.prove_github defer err
    T.no_error err
  cb()

exports.prove_twitter = (T,cb) ->
  unless found
    await user.prove_twitter defer err
    T.no_error err
  cb()
