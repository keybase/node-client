
libkb = require 'libkeybase'
assert = require 'assert'
{User,E} = libkb

# Your app needs to provide some idea of local storage that meets our requirements.
{LocalStore} = require 'myapp'

# Open the LocalStore, which can create one if none existed beforehand.
await LocalStore.open {}, defer err, store

# Load me...
await User.load { store, query : { keybase : "max" } }, defer err, me

# Loads a list of recruited users who are now ready to be verified.
# Makes an API to the server and verifies that I've signed them and they
# aren't expired..
await me.load_recruited_user_list {}, defer err, recruits

for r in recruits

  # The recruits are skeletons, so we still need to load their signature chain
  # from the server.
  await r.load {}, defer err
  idtab = r.get_identity_table()

  # Check the remote tabs as usual
  await idtab.check_remotes {}, defer err

  # Our assertions are preloaded in the object
  await idtab.assert {}, defer err

  # Does the following:
  #   1. Gets the needed KeyManager from me
  #   2. Gets the user's keymanager for encryption for the given app
  #   3. Decrypts and reencrypts
  await r.release { me } , defer err, secret

  # And now perform app-specific information with the secret...
