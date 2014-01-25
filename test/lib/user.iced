
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

#==================================================================

randhex = (len) -> prng(len).toString('hex')

#==================================================================

exports.User = class User

  constructor : ({@username, @email, @password, @homedir}) ->

  #---------------

  @generate : () -> 
    base = randhex(3)
    opts =
      username : "test_#{base}"
      password : randhex(6)
      email    : "test+#{base}@keybase.io"
      homedir  : path.join(config().scratch_dir(), "home_#{base}")
    new User opts

  #-----------------

  make_homedir : (cb) ->
    await mkdir_p @homedir, null, defer err
    cb err

  #-----------------

  make_key : () ->

  #-----------------

  push : () ->

  #-----------------

  signup : () ->

  #-----------------

  prove_twitter : () ->

  #-----------------

  prove_github : () ->

#==================================================================
