
{TmpKeyRing} = require '../../lib/keyring'
{KeyGen} = require '../../lib/keygen'
path = require 'path'
{config} = require '../lib/config'

#=======================================================

keygen = null
passphrase = "now is the time for all good men"
keyring = null

#=======================================================

exports.init = (T,cb) ->
  dir = path.join __dirname, "scratch"
  await TmpKeyRing.make defer err, tmp
  keyring = tmp
  T.no_error err
  cb()

#-----------------------

exports.gen = (T,cb) ->
  keygen = new KeyGen {
    username : "kahn",
    config : 
      master : bits : 1024
      subkey : bits : 1024
      expire : "10y"
    passphrase : passphrase
    ring : keyring
  }
  await keygen.gen defer err
  T.no_error err
  cb() 

#-----------------------

exports.encrypt_to_p3skb = (T,cb) ->
  await keygen.encrypt_to_p3skb defer err
  T.no_error err
  cb()

#-----------------------
