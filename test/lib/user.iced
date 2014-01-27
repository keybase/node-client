
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
{Engine} = require 'iced-expect'

#==================================================================

randhex = (len) -> prng(len).toString('hex')

#==================================================================

exports.User = class User

  constructor : ({@username, @email, @password, @homedir}) ->
    @keyring = null
    @_state = {}
    users().push @

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
    @_state.init = true
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

  _keybase_cmd : (inargs) -> 
    inargs.args = [ "--homedir", @keyring_dir() ].concat inargs.args
    config().keybase_cmd inargs
    return inargs

  #-----------------

  keybase : (inargs, cb) ->
    @_keybase_cmd inargs
    await run inargs, defer err, out
    cb err, out

  #-----------------

  keybase_expect : (args) ->
    inargs = { args }
    @_keybase_cmd inargs
    eng = new Engine inargs
    eng.run()
    return eng

  #-----------------

  make_keyring : (cb) ->
    await AltKeyRing.make @keyring_dir(), defer err, @keyring
    cb err

  #-----------------

  gpg : (args, cb) -> @keyring.gpg args, cb

  #-----------------

  grab_key : (cb) ->
    esc = make_esc cb, "User::grab_key"
    await keypool.grab esc defer tmp
    await tmp.load esc defer()
    @key = tmp.copy_to_keyring @keyring
    await @key.save esc defer()
    cb null

  #-----------------

  push_key : (cb) ->
    await @keybase { args : [ "push", @key.fingerprint() ], quiet : true }, defer err
    @_state.pushed = true unless err?
    cb err

  #-----------------

  signup : (cb) ->
    eng = @keybase_expect [ "signup" ]
    await eng.conversation [
        { expect : "Your desired username: " }
        { sendline : @username }
        { expect : "Your passphrase: " }
        { sendline : @password }
        { expect : "confirm passphrase: " }
        { sendline : @password },
        { expect : "Your email: "}
        { sendline : @email }
        { expect : "Invitation code: 123412341234123412341234" }
        { sendline : "" }
      ], defer err
    unless err?
      await eng.wait defer rc
      if rc isnt 0
        err = new Error "Command-line client failed with code #{rc}"
      else
        @_state.signedup = true
    cb err

  #-----------------

  prove_twitter : () ->

  #-----------------

  prove_github : () ->

  #-----------------

  has_live_key : () -> @_state.pushed and @_state.signedup and not(@_state_revoked)

  #-----------------

  revoke_key : (cb) ->
    await @keybase { args : [ "revoke", "--force" ], quiet : true }, defer err
    @_state.revoked = true unless err?
    cb err

#==================================================================

class Users

  constructor : () -> 
    @_list = [] 
    @_lookup = {}

  pop : () -> @_list.pop()

  push : (u) ->
    @_list.push u
    @_lookup[u.username] = u
  
  lookup : (u) -> @_lookup[u]

  cleanup : (cb) ->
    err = null
    for u in @_list when k.has_live_key()
      await u.revoke_key defer tmp
      if tmp?
        log.error "Error revoking user #{u.username}: #{err.message}"
        err = tmp
    cb err

#==================================================================

_users = new Users
exports.users = users = () -> _users

#==================================================================
