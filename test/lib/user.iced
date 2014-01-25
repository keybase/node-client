
#
# A file that wraps the creation and management of test
# users, potentially with features to access test twitter 
# and github accounts. As such, it might need access to
# a configuration file, since we don't want to push our
# test twitter/github credentials to github.
#

{prng} = require 'crypto'
{init,config} = require './config'
path = require 'path'
{mkdir_p} = require('iced-utils').fs
{make_esc} = require 'iced-error'
{log} = require '../../lib/log'
{AltKeyRing} = require('gpg-wrapper').keyring

#==================================================================

randhex = (len) -> prng(len).toString('hex')

#==================================================================

exports.User = class User

  constructor : ({@username, @email, @password, @homedir}) ->
    @keyring = null

  #---------------

  @generate : () -> 
    base = randhex(3)
    opts =
      username : "test_#{base}"
      password : randhex(6)
      email    : "test+#{base}@test.keybase.io"
      homedir  : path.join(config().scratch_dir(), "home_#{base}")
    new User opts

  #-----------------

  init : (cb) ->
    esc = make_esc cb, "User::init"
    await @make_homedir esc defer()
    await @make_keyring esc defer()
    cb null

  #-----------------

  make_homedir : (cb) ->
    await mkdir_p @homedir, null, defer err
    cb err

  #-----------------

  keyring_dir : () -> path.join(@homedir, ".gnupg")

  #-----------------

  make_keyring : (cb) ->
    await AltKeyRing.make @keyring_dir(), defer err, @keyring
    cb err

  #-----------------

  gpg : (args, cb) -> @keyring.gpg args, cb

  #-----------------

  make_key : (cb) ->
    esc = make_esc cb, "User::make_key"
    bits = 1024
    script = [
      "Key-Type: RSA"
      "Key-Length: #{bits}"
      "Subkey-Type: RSA"
      "Subkey-Length: #{bits}"
      "Name-Real: #{@username}"
      "Name-Email: #{@email}"
      "Expire-date: 10y"
      "%transient-key"
      "%no-protection"
      "%commit"
    ]
    args = [ "--gen-key", "--batch" ]
    stdin = script.join("\n")
    await @gpg { args, stdin }, defer err 
    @key = @keyring.make_key { username : @username } 
    await @key.load esc defer()
    await @key.read_uids_from_key esc defer uids
    @key._uid = uids[0]
    cb null

  #-----------------

  push : () ->

  #-----------------

  signup : () ->

  #-----------------

  prove_twitter : () ->

  #-----------------

  prove_github : () ->

#==================================================================


test = (cb) ->
  esc = make_esc cb, "test"
  await init { }, esc defer()
  user = User.generate()
  await user.init esc defer()
  await user.make_key esc defer()
  cb null

await test defer err
console.log err