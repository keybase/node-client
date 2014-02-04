
{TmpKeyRing} = require '../../lib/keyring'
{KeyManager} = require '../../lib/keymanager'
path = require 'path'
{config} = require '../lib/config'

#=======================================================

km2 = keymanager = null
passphrase = "now is the time for all good men"
keyring = null
p3skb = null

#=======================================================

exports.init = (T,cb) ->
  dir = path.join __dirname, "scratch"
  await TmpKeyRing.make defer err, tmp
  keyring = tmp
  T.no_error err
  cb()

#-----------------------

exports.gen = (T,cb) ->
  args = 
    username : "kahn",
    config : 
      master : bits : 1024
      subkey : bits : 1024
      expire : "10y"
    passphrase : passphrase
    ring : keyring 
  await KeyManager.generate args, defer err, tmp
  T.no_error err
  keymanager = tmp
  cb() 

#-----------------------

exports.export_to_p3skb = (T,cb) ->
  await keymanager.export_to_p3skb defer err, tmp
  T.no_error err
  p3skb = tmp
  cb()

#-----------------------

exports.import_from_p3skb = (T,cb) ->
  args = 
    raw : p3skb
    passphrase : passphrase
    tsenc : keymanager.get_tsenc() 
  await KeyManager.import_from_p3skb args, defer err, tmp
  T.no_error err
  km2 = tmp
  cb()

#-----------------------

exports.save = (T,cb) ->
  await TmpKeyRing.make defer err, ring
  T.no_error err
  await km2.save_to_ring { ring }, defer err
  T.no_error err
  await ring.list_fingerprints defer err, ret
  T.no_error err
  T.equal ret.length, 1, "Only got one key back"
  T.equal ret[0], keymanager.key.fingerprint(), "The same PGP fingerprint"
  await ring.nuke defer err
  T.no_error err
  cb()

#-----------------------

exports.finish = (T,cb) ->
  await keyring.nuke defer err
  cb()

#-----------------------
