
# Some pseudocode for a 3rd-party app, that uses keybase for key delegation...

libkb = require 'libkeybase'
{URI,api,KeyManager,User} = libkb
{CSR} = libkb.api

# Load up the "me" user as usual to access my public key info.
{LocalStore} = require 'myapp'
await LocalStore.open {}, defer err, store
await User.load { store, query : { keybase : "max" }, opts : {} }, defer err, me

appid = "aabbcc15"
device_id = "iphone-4"

# Application master key, shared across all devices; might be discarded if already registered
# uri.format() would output keybase://max@/aabbcc15
uri = new URI { username : "max", host : null, app_id }

# Generate a new random key.  You can use our
await KeyManager.generate { algo : "ed25519", params : {}, uri }, defer err, km_master

# device-specific key
# uri.format() would Output keybase://max@keybase.io/aabbcc15/iphone-4
uri = new URI { username : "max", host : null, app_id, device_id, host : "keybase.io" }
await KeyManager.generate { algo : "ed25519", params : {}, uri }, defer err, km_device

keys = { master : km_master, device : km_device }

# Here are the steps in generating a 'CSR':
#  1. For each key in the keyset
#     a. Sign the user's primary key bundle with the new key
#  2. Bundle all sigs, and keys into a JSON object
#  3. Generate a random, unguessable number too (maybe?)
await CSR.generate { keys, user }, defer err, csr

# Also might want to piggy-back on the CSR a secret shared across all device installs
# of this app, though the feature is optional...
ops = ENCRYPT
uri = null # the primary (default) key manager
await user.load_key_manager { uri, ops }, defer err, km_primary
await km_master.export_private {}, defer err, km_master_priv

# Problem: if encrypt_for is a PGP key and sign_with is some other format,
# then we can't use the standard PGP sign-then-encrypt system.
await box { sign_with : km_master, encrypt_for : km_primary, data : km_master_priv }, defer err, ctext

# Now affix the piggy-backed reencryption request onto the CSR.
csr.piggy_back { ciphertext: ctext }

# Compute some sort of hash or visual hash so that the user isn't tricked into
# approving a bogus CSR over on keybase
await csr.compute_hash {}, defer err, hash

# Post this CSR to keybase and get back an object to track and/or wait for
# the auth to finish
await csr.post_to_server {}, defer err, external_csr_auth

# Direct the user to this Web URI, maybe?
# Might also consider cross-app calls on iPhone or Android
console.log external_csr_auth.get_web_uri()

# Poll and/or open a socket to figure out when it's complete.
await external_csr_auth.wait {}, defer err, status

# not sure how this is going to work --- we can get a new master key
await external_csr_auth.unbox { keyring : km_device }, defer err, plaintext
