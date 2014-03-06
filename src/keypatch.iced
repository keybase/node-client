
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
    await prompt_passphrase { prompt : "Passphrase for key '#{uid.utf8()}'" } , esc defer pp
    cb null

  #--------------

  needs_patch : () -> not @key.has_canonical_username()

  #--------------

  run_patch_sequence : (cb) ->
    esc = make_esc cb, "KeyPatcher::run_patch_sequence"
    await @import_secret_key esc defer()
    await @patch_key esc defer()
    cb null

  #--------------

  patch_key : (cb) ->
    esc = make_esc cb, "KeyPatcher::run_patch"
    pgp = @km.pgp
    uid = @lib.UserID.make env().make_pgp_uid()
    pgp.userids = [ uid ]
    pgp.subkeys = []
    #await pgp.self_sign_primary { raw_payload : true }, esc defer raw
    #gargs = 
    #  args : [ "-u", @key.fingerprint(), "--detach-sign" ]
    #  stdin : raw
    #  quiet : true
    #await @key.gpg gargs, esc defer out
    #[err, packets] = @lib.parse out
    #console.log err
    #console.log packets
    #console.log packets[0].hashed_subpackets
    cb new Error "bailing out for debugging purposes"

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
      await @prompt_patch esc defer go
      await @run_patch_sequence esc defer() if go

    cb null, @did_patch

  #--------------

#=====================================================

