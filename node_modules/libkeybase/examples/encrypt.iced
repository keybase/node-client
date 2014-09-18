
libkb = require 'libkeybase'
{Assertion,User} = libkb

# Your app needs to provide some idea of local storage that meets our requirements.
{LocalStore} = require 'myapp'

# Open the LocalStore, which can create one if none existed beforehand.
await LocalStore.open {}, defer err, store

# In this case, we assume that the user exists, and that we don't want to work
# around a failure in loading him/her.  In contrast, we'll see other versions of
# this process in which we make temporary provisions based on a user not existing
# (see recruit.json).

# Steps to loading a user:
#
#   1. Fetching all signature data from the server (or from local storage)
#   2. Cryptographic Checks
#       a. Checking the tail of the sigchain is in the Merkle Tree.
#       b. Checking the merkle tree is in the blockchain (optional)
#       c. Checking all links of the signature chain point to each other.
#       d. Checking that the tail is signed by the most recent active public key (the user might have
#          switched halfway down the chain).
#   3. Identity Table Construction - Flatten the signature chain into a final "identity table"
#      of remote identities that link to this username/key combination.
#
# Next, 4a, b, and c can happen in any order:
#
#   4a. Remote check --- check that all proofs in the identity table still exist
#   4b. Tracking resolution --- check the computed identity table against any existing tracker statements,
#       and resolve what needs to be fixed to bring any stale tracking up-to-date
#   4c. Assertions -- check the user's given assertions against the computed identity table
#
# Next, 5 can happen only after all of 4a, b, and c
#
#   5. track/retrack -- sign a new tracking statement, if necessary, signing off on the above computations.
#

# Load a user from the server, and perform steps 1, 2, and 3.  Recall that step 2b is optional,
# and you can provide options here to enable it.  If you do provide that option, there might be a
# latency of up to 6 hours.
#
# The Store is optional, but if provided, we can check the store rather than
# fetch from the server.
await User.load { store, query : { keybase : "max" }, opts : {} }, defer err, me

# As in 4c above...
assertion = Assertion.compile "(key://aabbccdd && reddit://maxtaco && (https://goobar.com || http://goobar.com || dns://goobar.com)))"
await me.assert { assertion }, defer err

# Load a second user...
await User.load { store, query : { "twitter" : "malgorithms" } }, defer err, chris

#
# Note that there is a 1-to-1 correspondence between the IdentityTable object and the
# User object, but they are split apart for convenience.
#
idtab = chris.get_identity_table()

# As in 4b above...
#
# State can be: NONE, if I haven't tracked Chris before; OK if my tracking
# statement is fully up-to-date, STALE if my tracking statement is out-of-date,
# or SUBSET, if it's a proper subset of the current state.
#
await idtab.check_tracking { tracker : me }, defer err, state

# As in 4a above.
#
# An error will be returned if there was a catastrophic failure, not if
# any one of the proofs failed. Check the status field for OK if all succeded, or
# PARTIAL_FAILURE if some failed.

await idtab.check_remotes {}, defer err, status, failures

# Outputs any failures in JSON format, though you can query the idtab in a number of different ways
# (which aren't finalized yet...)
failures = idtab.get_failures_to_json()

# As in 4c, optional assertions against the identity table
await idtab.assert { assertion : [ { "key" : "aabb" }, { "reddit" : "maxtaco" } ] }, defer err

# Fetch a key manager for a particular app (or for the main app if none specified), and for
# the given public key operations.
await chris.load_key_manager { { subkey_name : "myencryptor" }, ops }, defer err, km

# Also possible to list subkeys; will generate a list of active keys. Can query by
# prefix, or regex, or exact match (name).
await chris.list_keys { prefix : "myapp." }, defer err, keys
