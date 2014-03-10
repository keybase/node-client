
{constants} = require './constants'
{make_esc} = require 'iced-error'
{load_key,master_ring} = require './keyring'
{prompt_passphrase,prompt_for_int} = require './prompter'
{env} = require './env'
log = require './log'
{E} = require './err'

#=====================================================

exports.KeyPatcher = class KeyPatcher

  #--------------

  constructor : ({ @key, @opts } ) ->
    @ring or= master_ring()
    kbpgp = require('kbpgp')
    @lib =
      KeyManager : kbpgp.KeyManager
      UserID     : kbpgp.opkts.UserID
      parse      : kbpgp.parser.parse
    @did_patch = false
    @em = env().keybase_email()

  #--------------

  import_key : (cb) ->
    await @lib.KeyManager.import_from_armored_pgp { raw : @key.key_data() }, defer err, @km
    cb err

  #--------------

  import_secret_key : (cb) ->
    esc = make_esc cb, "KeyPatcher::import_secret_key"
    await load_key { fingerprint : @key.fingerprint(), secret : true  }, esc defer k
    await @lib.KeyManager.import_from_armored_pgp { raw : k.key_data() }, esc defer @skm
    uid = @lib.UserID.make k.uid()
    if @skm.is_pgp_locked()
      await prompt_passphrase { prompt : "Passphrase for key '#{uid.utf8()}'", short : true } , esc defer passphrase
      log.debug "+ unlock_pgp"
      await @skm.unlock_pgp { passphrase }, esc defer()
      log.debug "- unlock_pgp"
    cb null

  #--------------

  needs_patch : () -> not @key.has_canonical_username()

  #--------------

  export_patch : (cb) ->
    log.debug "+ KeyPatcher::export_patch"
    esc = make_esc cb, "KeyPatcher::export_patch"
    await @skm.export_pgp_public { regen : true }, esc defer msg
    await @ring.gpg { args : [ "--import" ], quiet : true, stdin : msg }, esc defer()
    log.debug "- KeyPatcher::export_patch"
    cb null

  #--------------

  reload_key : (cb) ->
    await load_key { fingerprint : @key.fingerprint(), secret : false }, defer err, @key
    cb err

  #--------------

  verify : (cb) ->
    err = if @key.has_canonical_username() then null
    else new E.PatchError "Key update filaed; please report this bug"
    cb err

  #--------------

  run_patch_sequence : (cb) ->
    esc = make_esc cb, "KeyPatcher::run_patch_sequence"
    await @import_secret_key esc defer()
    await @patch_key esc defer()
    await @export_patch esc defer()
    await @reload_key esc defer()
    await @verify esc defer()
    cb null

  #--------------

  get_key : () -> @key

  #--------------

  patch_key : (cb) ->
    esc = make_esc cb, "KeyPatcher::run_patch"
    pgp = @skm.pgp
    uid = @lib.UserID.make env().make_pgp_uid()
    pgp.userids = [ uid ]
    pgp.subkeys = []

    # Fix this, make it last only as long as the longest UID.
    # See https://github.com/keybase/node-client/issues/121
    pgp.primary.lifespan.expire_in = 0 # never expires

    await @skm.sign {}, esc defer()
    cb null

  #--------------

  prompt_patch : (cb) ->
    em = @uid.get_email()

    width = 70
    line = ("-" for i in [0...width]).join('')
    msg = "Enabling #{em}"
    diff = width - msg.length
    spc = if diff > 0 then (' ' for i in [0...(diff >> 1)]).join('') else ''
    msg = """

#{line}
#{spc}#{msg}
#{line}

All keybase users get a free @keybase.io address, which 
forwards incoming mail and acts, for privacy, as the return
address on outgoing mail generated via `keybase email`.

This feature works **much** better with existing GPG clients
if you add #{em} to your public key.

You have 3 options:

  (1) Exit now; I can add #{em} with GPG or my own software
  (2) Allow keybase to add it for me
  (3) Skip this step and do it later (not recommended)

"""
    if @opts.skip_add_email then go = false
    else if @opts.add_email then go = true
    else
      do_warning = false
      log.console.log msg
      prompt = "Your choice"
      err = null
      go = false
      args = 
        prompt : "Your choice"
        low : 1
        hi : 3
        defint : 2
        hint : "pick 1,2 or 3"
        first_prompt : " (2)"
      await prompt_for_int args, defer err, i
      unless err?
        switch i 
          when 1
            err = new E.CancelError "please edit your key and rerun this command"
          when 2
            do_warning = true
            go = true
          when 3
            go = false
      if do_warning
        w = """

#{line}

OK. Keybase will now modify your public key by merging
#{em} into its approved list of emails.  This
operation requires temporary local access to your secret 
key and then throws it away. The client will not write
your decrypted secret key to disk or to the server.

"""
        log.console.log w
    cb err, go
  

  #--------------

  run : ({interactive}, cb) ->
    esc = make_esc cb, "KeyPatcher::run_patch"
    await @import_key esc defer()

    if @needs_patch()
      @uid = @lib.UserID.make env().make_pgp_uid()
      await @prompt_patch esc defer go_patch
      await @run_patch_sequence esc defer() if go_patch

    cb null, go_patch

#=====================================================

