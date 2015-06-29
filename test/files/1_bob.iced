
{User, signup} = require '../lib/user'
log = require '../../lib/log'

signup_args = { twitter : true, github : true, save_pw : true }

exports.signup_bob = (T,cb) ->
  await signup T, 'bob', signup_args, defer u
  cb()

exports.signup_charlie = (T,cb) ->
  await signup T, 'charlie', signup_args, defer u
  cb()
