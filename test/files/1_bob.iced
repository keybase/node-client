
{User} = require '../lib/user'
bob = null
log = require '../../lib/log'
keypool = require '../lib/keypool'

exports.signup = (T,cb) ->
  bob = User.generate 'bob'
  T.assert bob, "bob was generated"
  await bob.check_if_exists defer found
  if found
    log.info "Bob found; not remaking him"
    await bob.login defer esc
    T.no_error err
  else
    log.info "Bob not found; remaking him "
    await keypool.grab defer err, key
    await bob.full_monty T, { twitter : true, github : false, save_pw : true }, defer err
    T.no_error err
  cb()
