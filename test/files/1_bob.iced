
{User} = require '../lib/user'
log = require '../../lib/log'
keypool = require '../lib/keypool'

exports.signup_bob = (T,cb) ->
  await signup T, 'bob', defer()
  cb()

exports.signup_charlie = (T,cb) ->
  await signup T, 'charlie', defer()
  cb()

signup = (T,name,cb) ->
  u = User.generate name
  T.assert u, "#{name} was generated"
  await u.check_if_exists defer found
  if found
    log.info "#{name} found; not remaking him"
    await keypool.grab defer err, key
    T.no_error err
    await u.login defer err
    T.no_error err
    await u.load_status defer err
    T.no_error err
  else
    log.info "#{name} not found; remaking him "
    await u.full_monty T, { twitter : true, github : true, save_pw : true }, defer err
    T.no_error err
  cb()
