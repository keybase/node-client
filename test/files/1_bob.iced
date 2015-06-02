
{User} = require '../lib/user'
log = require '../../lib/log'

exports.signup_bob = (T,cb) ->
  await signup T, 'bob', defer()
  cb()

exports.signup_charlie = (T,cb) ->
  await signup T, 'charlie', defer()
  cb()

signup = (T,name,cb) ->
  await User.load_or_gen name, defer u, is_new
  T.assert u, "#{name} was generated"
  if not is_new
    log.info "#{name} found; not remaking them"
    await u.login defer err
    T.no_error err
    await u.load_status defer err
    T.no_error err
  else
    log.info "#{name} not found; remaking them "
    await u.full_monty T, { twitter : true, github : true, save_pw : true }, defer err
    T.no_error err
  cb()
