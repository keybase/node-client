
{constants} = require './constants'
{make_esc} = require 'iced-error'
{PackageJson} = require './package'
{init,master_ring} = require './keyring'
{env,init_env} = require './env'

#=====================================================

exports.KeyManager = class KeyManager

  #--------------

  constructor : ({@username, @config, @passphrase, @ring, @tsenc}) ->
    @ring or= master_ring()
    @key = null
    @lib = 
      KeyManager : require('kbpgp').KeyManager
      Encryptor : require('triplesec').Encryptor

  #--------------

  @generate : ({username, config, passphrase, ring}, cb) ->
    username or= env().get_username()
    config or= constants.keygen
    ring or= master_ring()
    km = new KeyManager { username, config, passphrase, ring }
    await km._gen defer err
    km = null if err?
    cb err, km

  #--------------

  _gen : (cb) ->
    esc = make_esc cb, "KeyGen::Gen"
    h = constants.canonical_host
    email = @username + "@#{h}"
    script = [
      "%echo generating"
      "Key-Type: RSA"
      "Key-Length: #{@config.master.bits}"
      "Subkey-Type: RSA"
      "Subkey-Length: #{@config.subkey.bits}"
      "Name-Real: #{h}/#{@username}"
      "Name-Email: #{email}"
      "Expire-date: #{@config.expire}"
      "Passphrase: #{@passphrase}"
      "%commit"
    ]
    stdin = script.join("\n")
    args = [ "--batch", "--gen-key" ]
    await @ring.gpg { args, stdin, quiet : true }, esc defer()
    @key = @ring.make_key { username : "<#{email}>", secret : true }
    await @key.load esc defer()
    cb null

  #--------------

  get_tsenc : () ->
    unless @tsenc
      @tsenc = new @lib.Encryptor { key : new Buffer(@passphrase, 'utf8') }
    return @tsenc

  #--------------

  export_to_p3skb : (cb) ->
    esc = make_esc cb, "KeyManager::encrypt_to_p3skb"
    raw = @key.key_data().toString('utf8')
    await @lib.KeyManager.import_from_armored_pgp { raw }, esc defer @km, warnings
    @warn "Export to P3SKB format", warnings
    await @km.unlock_pgp { @passphrase }, esc defer()
    await @km.sign {}, esc defer()
    await @km.export_private_to_server { tsenc : @get_tsenc() }, esc defer @p3skb
    cb null, @p3skb

  #--------------

  set_passphrase : (p) ->
    @passphrase = p
    @tsenc = null

  #--------------

  @import_from_p3skb : ({raw, ring, tsenc, passphrase}, cb) ->
    km = new KeyManager { ring, tsenc, passphrase }
    await km._import_from_p3skb {raw }, defer err
    km = null if err?
    cb err, km

  #--------------

  warn : (what, warnings) ->
    for w in warnings.warnings()
      log.warn "#{what}: #{w}"

  #--------------

  save_to_ring : ({passphrase, ring}, cb) ->
    esc = make_esc cb, "KeyManager::save_to_ring"
    @ring = ring if ring?
    @set_passphrase(passphrase) if passphrase?
    await @km.sign {}, esc defer()
    await @km.export_pgp_private_to_client { @passphrase }, esc defer key_data
    @key = @ring.make_key { key_data, fingerprint : @km.get_pgp_fingerprint() }
    await @key.save esc defer()
    cb null

  #--------------

  _import_from_p3skb : ({raw}, cb) ->
    esc = make_esc cb, "KeyManager::_import_from_p3skb"
    await @lib.KeyManager.import_from_p3skb { raw }, esc defer @km, warnings
    @warn "Import from P3SKB format", warnings
    if @km.is_p3skb_locked() and @passphrase?
      await @km.unlock_p3skb { tsenc : @get_tsenc() }, esc defer()
    cb null

#=====================================================
