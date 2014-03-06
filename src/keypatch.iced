
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

  constructor : ({ @key } ) ->
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
    await @skm.sign {}, esc defer()
    cb null

  #--------------

  prompt_patch : (cb) ->
    em = @uid.get_email()
    log.console.log  """

Keybase forwards mail for its users to the email addresses of their choice.
This feature works much better (and your email is less likely to be marked as spam)
if you add your Keybase.io identity --- <#{em}> --- to your key.
Would you like to:

    (1) Allow this program to add your keybase email to your key (we'll prompt your for your password)
    (2) Quit out and edit your key via GPG (add email #{em})
    (3) Skip this step

"""
    prompt = "Your choice"
    err = null
    go = false
    await prompt_for_int prompt, 1, 3, defer err, i
    unless err?
      switch i 
        when 1
          go = true
        when 2
          err = new E.CancelError "please edit your key and rerun this command"
        when 3
          go = false
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

