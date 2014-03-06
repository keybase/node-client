
{constants} = require './constants'
{make_esc} = require 'iced-error'
{master_ring} = require './keyring'
{prompt_yn} = require './prompter'
{env} = require './env'
{parse} = require './parser'

#=====================================================

exports.KeyPatcher = class KeyPatcher

  #--------------

  constructor : ({ @key } ) ->
    @ring or= master_ring()
    kbpgp = require('kbpgp')
    @lib =
      KeyManager : kbpgp.KeyManager
      UserID     : kbpgp.opkts.UserID
    @did_patch = false
    @em = env().keybase_email()

  #--------------

  import_key : (cb) ->
    await @lib.KeyManager.import_from_armored_pgp { raw : @key_data() }, defer err, @km
    cb err

  #--------------

  needs_patch : () -> not @key.has_canonical_name()

  #--------------

  run_patch : (cb) ->
    esc = make_esc cb, "KeyPatcher::run_patch"
    pgp = @km.pgp
    uid = new @lib.UserID { components : env().make_pgp_uid() } 
    pgp.userids = [ uid ]
    await pgp.self_sign_primary { raw_payload : true }, esc defer raw
    gargs = 
      args : [ "-u", @key.fingerprint(), "--sign" ]
      stdin : raw
      quiet : true
    await @key.gpg gargs, esc defer out
    [err, packets] = parse out
    console.log err
    console.log out
    cb new Error "bailing out for debugging purposes"

  #--------------

  run : ({interactive}, cb) ->
    esc = make_esc cb, "KeyPatcher::run_patch"
    await @import_key esc defer()

    if @needs_patch()
      prompt = "Add the userid <#{@em}> to your key"
      await prompt_yn { prompt, defval : true }, esc defer go
    else
      go = false

    await @run_patch esc defer() if go

    cb null, @did_patch

  #--------------

#=====================================================

