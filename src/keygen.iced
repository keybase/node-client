
{constants} = require './constants'
{make_esc} = require 'iced-error'
{PackageJson} = require './package'
{init,master_ring} = require './keyring'
{env,init_env} = require './env'

#=====================================================

exports.KeyGen = class KeyGen

  #--------------

  constructor : ({@username, @config, @passphrase, @ring}) ->
    @ring or= master_ring()
    @key = null

  #--------------

  gen : (cb) ->
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
      "Name-Comment: #{(new PackageJson).identify_as()}"
      "Name-Email: #{email}"
      "Expire-date: #{@config.expire}"
      "Passphrase: #{@passphrase}"
      "%commit"
    ]
    stdin = script.join("\n")
    args = [ "--batch", "--gen-key" ]
    await @ring.gpg { args, stdin, quiet : false }, esc defer()
    @key = @ring.make_key { username : "<#{email}>", secret : true }
    await @key.load esc defer()
    cb null

  #--------------

  encrypt_to_p3skb : (cb) ->
    {KeyManager} = require 'kbpgp'
    {Encryptor} = require 'triplesec'
    esc = make_esc cb, "KeyGen::encrypt_to_p3skb"
    raw = @key.key_data().toString('utf8')
    await KeyManager.import_from_armored_pgp { raw }, esc defer @km
    await @km.unlock_pgp { @passphrase }, esc defer()
    @tsenc = new Encryptor { key : new Buffer(@passphrase, 'utf8') }
    await @km.sign {}, esc defer()
    await @km.export_private_to_server { @tsenc }, esc defer @p3skb
    cb null, @p3skb

#=====================================================

test = (cb) ->
  init_env()
  env().set_argv {}
  init()
  kg = new KeyGen {
    username : "tacotime",
    config : constants.keygen,
    passphrase : "now is the time for all men"
  }
  await kg.gen defer err
  console.log err
  await kg.encrypt_to_p3skb defer err
  console.log err
  console.log kg.p3skb
  cb()

