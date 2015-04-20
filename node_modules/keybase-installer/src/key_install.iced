
{make_esc} = require 'iced-error'
{chain} = require('iced-utils').util
{keyring} = require 'gpg-wrapper'
{fpeq} = require('pgp-utils').util
{hash_json} = require './util'
log = require './log'

##========================================================================

exports.KeyInstall = class KeyInstall

  #-----------------
  
  constructor : (@config, keyset) ->
    @_keyset = keyset
    @_tmp_keyring = null
    @_keys = {}

  #-----------------

  make_tmp_keyring : (cb) ->
    log.debug "| KeyInstaller::make_tmp_keyring"
    await keyring.QuarantinedKeyRing.make defer err, @_tmp_keyring
    cb err

  #-----------------

  cleanup : (cb) ->
    log.debug "+ Cleaning up tmp keyring #{@_tmp_keyring}"
    if @_tmp_keyring?
      await @_tmp_keyring.nuke defer err
      if err?
        log.warn "Error cleaning up temporary keyring: #{err.message}"
    log.debug "- Cleaning up tmp keyring #{@_tmp_keyring}"
    cb()

  #-----------------

  temporary_import : (cb) ->
    esc = make_esc cb, "KeyInstaller::temporary_import"
    log.debug "+ KeyInstaller::temporary_import"
    source = @_keyset.keys.code
    @_keys.code = k = @_tmp_keyring.make_key {
      key_data : source.key_data,
      fingerprint  : source.fingerprint,
      username : "code@keybase.io"
    }
    @_tmp_keyring.set_fingerprint source.fingerprint

    await k.save esc defer err
    await @_tmp_keyring.list_fingerprints esc defer fps

    msg = if fps.length is 0 then "key save failed; no fingerprints"
    else if fps.length > 1 then "keyring corruption; too many fingerprints found"
    else if not fpeq((a = fps[0]), (b = @_keyset.keys.code.fingerprint))
      "fingerprint mismatch after import: #{a} != #{b}"

    err = if msg? then new Error(msg) else null
    log.debug "- KeyInstaller::temporary_import"
    cb err

  #-----------------

  check_self_sig : (cb) ->
    sig = @_keyset.self_sig
    @_keyset.self_sig = null
    log.debug "+ KeyInstaller::check_self_sig"
    payload = hash_json @_keyset
    await @_keys.code.verify_sig { which : "self sig on keyset", payload, sig }, defer err
    log.debug "- KeyInstaller::check_self_sig"
    cb err

  #-----------------

  full_import : (cb) ->
    esc = make_esc cb, "KeyInstall::full_import"
    log.debug "+ KeyInstaller::full_import"
    master = @config.master_ring()
    source = @_keyset.keys.index
    @_keys.index = k = master.make_key {
      key_data : source.key_data,
      fingerprint : source.fingerprint,
      username : "index@keybase.io"
    }
    await k.save esc defer()
    await @_keys.code.commit { ring : master }, esc defer()
    log.debug "- KeyInstaller::full_import"
    cb null

  #-----------------

  revoke_1 : (k, v, cb) ->
    log.debug "| Revoking key #{k}"
    await keyring.master_ring().gpg { args : [ "--import" ] , stdin : v, quiet : true }, defer err
    cb err

  #-----------------

  revoke_all : (cb) ->
    esc = make_esc cb, "KeyInstall::revoke_all"
    if @_keyset.revocation?
      for k,v of @_keyset.revocation
        await @revoke_1 k, v, esc defer()
    cb null

  #-----------------

  keys : () -> @_keys

  #-----------------

  run : (cb) ->
    esc = make_esc cb, "KeyInstall:run2"
    log.debug "+ KeyInstaller::run"
    log.info "Installing keyset version #{@_keyset.version}"
    cb = chain cb, @cleanup.bind(@)
    await @make_tmp_keyring esc defer()
    await @temporary_import esc defer()
    await @check_self_sig esc defer()
    await @full_import esc defer()
    await @revoke_all esc defer()
    log.debug "- KeyInstaller::run"
    cb null

##========================================================================

