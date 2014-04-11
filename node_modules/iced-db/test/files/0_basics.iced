
{E,DB} = require '../../lib/main'
{db} = require './lib'

#=================================

exports.setup = setup = (T,cb) ->
  await db.create defer err
  T.no_error err
  cb()

#=================================

exports.put_get_del_0 = (T, cb) ->

  await db.put { key : "max", value : "krohn" }, defer err
  T.no_error err
  await db.get { key  : "max" }, defer err, val
  T.no_error err
  T.assert val?, "a value came back"
  T.equal "krohn", val.toString('utf8'), "the right value"
  await db.get { key : "chris" }, defer err, val
  T.assert err?, "got an error back"
  T.assert (err instanceof E.NotFoundError), "not found error"
  T.assert not(val?), "no val"
  await db.del { key : "max" }, defer err
  T.no_error err
  await db.get { key : "max" }, defer err, val
  T.assert err?, "error happened"
  T.assert (err instanceof E.NotFoundError), "not found error"
  T.assert not(val?), "no value"
  await db.del { key : "max" }, defer err
  T.assert err?, "error happened"
  T.assert (err instanceof E.NotFoundError), "not found error"
  await db.del { key : "chris" }, defer err
  T.assert err?, "error happened"
  T.assert (err instanceof E.NotFoundError), "not found error"
  cb()

#=================================

exports.put_get_json_1 = (T,cb) ->
  obj = { foo : [1,2,3], bar : [ { biz: 1, jam : [1,2,34]}]}
  key = "k1"
  await db.put { key, value : obj, json : true }, defer err
  T.no_error err
  await db.get { key }, defer err, val
  T.no_error err
  T.equal obj, val, "json object came back"
  obj.boop = true
  k2 = "k2"
  await db.put { key : k2, value : obj, json : true }, defer err
  T.no_error err
  await db.get { key : k2 }, defer err, val
  T.no_error err
  T.equal obj, val, "json object came back"
  cb()

#=================================

exports.put_key_get_hkey = (T,cb) ->
  key = "k3"
  value = 1
  await db.put { key, value, json : true }, defer err, { hkey }
  T.no_error err
  await db.get { hkey }, defer err, val2
  T.no_error err
  T.equal value, val2, "value was right"
  cb()

#=================================
