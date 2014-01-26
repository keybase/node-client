
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
gpgw = require 'gpg-wrapper'
{AltKeyRing} = gpgw.keyring
{run} = gpgw
keypool = require './keypool'

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
    await @grab_key esc defer()
    await @write_config esc defer()
    cb null

  #-----------------

  write_config : (cb) ->
    esc = make_esc cb, "User::write_config"
    await @keybase { args : [ "config" ], quiet : true }, esc defer()  
    args = [
      "config"
      "--json"
      "server"
      JSON.stringify(config().server_obj())
    ]
    await @keybase { args, quiet : true }, esc defer()
    cb null

  #-----------------

  make_homedir : (cb) ->
    await mkdir_p @homedir, null, defer err
    cb err

  #-----------------

  keyring_dir : () -> path.join(@homedir, ".gnupg")

  #-----------------

  keybase : (inargs, cb) ->
    inargs.args = [
      "--homedir"
      @homedir
    ].concat inargs.args
    inargs.name = path.join __dirname, "..", "..", "bin", "main.js"
    await run inargs, defer err, out
    cb err, out

  #-----------------

  make_keyring : (cb) ->
    await AltKeyRing.make @keyring_dir(), defer err, @keyring
    cb err

  #-----------------

  gpg : (args, cb) -> @keyring.gpg args, cb

  #-----------------

  grab_key : (cb) ->
    esc = make_esc cb, "User::grab_key"
    await keypool.grab defer err, tmp 
    await tmp.load esc defer()
    @key = tmp.copy_to_keyring @keyring
    await @key.save esc defer()
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
  cb null

await test defer err
console.log err