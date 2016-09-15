## 0.8.27 (2016-09-15)

- Uninstall instructions too

## 0.8.26 (2016-07-21)

END OF LIFE
 - Disable all access and redirect to: https://keybase.io/download

## 0.8.25 (2015-11-30)

bugfix:
  - allow invitation codes other than 24 characters in length

## 0.8.24 (2015-11-24)

bugfix:
  - more work arounds for usernames with upper-case characters
  - emerg fix w/ coinbase scraper

## 0.8.23 (2015-10-21)

bugfix:
  - Import sigchain reset detection fixes from libkeybase.
  - Update the "revoke" command to use a working endpoint.

## 0.8.22 (2015-10-05)

bugfix:
  - Import broken reverse-sig fix from libkeybase (libkeybase-js/issues#5)

## 0.8.21 (2015-10-02)

bugfix:
  - Import another PGP expiration time fix from kbpgp (keybase/kbpgp#101)

## 0.8.20 (2015-09-21)

Bugfix:
  - Fix bug with 0.8.19 in the case of a user who hasn't self-signed a PGP key
    uploaded via the web site.
  - Special cases users who signed incorrect prev hashes due to a temporary
    server bug that stripped whitespace from payloads.

## 0.8.19 (2015-09-18)

Bugfix:
  - Workaround for: https://github.com/keybase/keybase-issues/issues/1765

Enhancements:
  - Support for full PGP uploading

## 0.8.18 (2015-08-14)

Bugfix:
  - Update kbpgp again, for https://github.com/keybase/keybase-issues/issues/1736

## 0.8.17 (2015-08-13)

Bugfix:
  - Updated kbpgp and libkeybase to address:
    - Brainpool curves: https://github.com/keybase/keybase-issues/issues/1333
    - UserID merging: https://github.com/keybase/keybase-issues/issues/1730

## 0.8.16 (2015-07-30)

Bugfix:
  - Dropping revoked subkeys with merging PGP key versions:
    https://github.com/keybase/kbpgp/issues/83
  - Some PGP keys failing to import:
    https://github.com/keybase/kbpgp/issues/80

## 0.8.15 (2015-07-28)

Bugfix:
  - Fix `keybase revoke` when the user has an unproven PGP key.

## 0.8.14 (2015-07-25)

Bugfix:
  - keybase/keybase-issues#1707

## 0.8.13 (2015-07-24)

Bugfix:
  - Pull in another fix from kbpgp, reverting previous.

## 0.8.12 (2015-07-21)

Bugfix:
  - Pull in a fix from kbpgp for calculating key creation times.
    (keybase/keybase-issues#1686)

## 0.8.11 (2015-07-20)

Bugfix:
  - Several bugs related to accounts with no signatures, or which have
    been recently reset (a la `keybase revoke`).

## 0.8.10 (2015-07-16)

Bugfix:
  - Fix `keybase status` when the user has no key.
  - Fix id commands like `keybase id twitter://malgorithms`.

## 0.8.9 (2015-07-08)

Bugfix:
  - Cleaner fix for the preceding bug:
    - Upgrade to libkeybase @ 1.2.12
    - Upgrade to kbpgp @ 2.0.27

## 0.8.8 (2015-07-05)

Bugfix:
  - Address: https://github.com/keybase/keybase-issues/issues/1656
    - Generate fix: not always last writer wins on PGP public key bundles
      if there were multiple updates, since import subkeys might have
      disappeared.
    - Upgrade to libkeybase @ 1.2.11
    - Upgrade to kbpgp @ 2.0.26

## 0.8.7 (2015-07-05)

Bugfix:
  - We had a server-side bug in username->UID conversion, in which
    usernames weren't toLowerCased()'d before hashing. Works around it.
    - See bug: https://github.com/keybase/keybase-issues/issues/1655 

## 0.8.6 (2015-07-03)

Bugfix:
  - Don't expire subkeys if they were valid at the time of the
    signature in question.  Found bug with (`keybase id bcrypt`)

## 0.8.5 (2015-07-02)

Bugfix:
  - https://github.com/keybase/keybase-issues/issues/1654

## 0.8.4 (2015-07-02)

Bugfixes:
  - https://github.com/keybase/keybase-issues/issues/1653

## 0.8.3 (2015-07-01)

Bugfixes:
  - Fix for keybase/libkeybase-js#3

## 0.8.2 (2015-07-01)

Bugfixes:
  - Use a version of libkeybase that doesn't bundle the test vectors, to reduce
    package size.

## 0.8.1 (2015-07-01)

Bugfixes:
  - Stop complaining for users with broken chain link ctimes.

## 0.8.0 (2015-07-01)

Features:
  - Go-client forward comptability; support full sigchains, with sibkeys,
    and multiple PGP keys.
  - Use libkeybase-js for most sigchain manipulation.

Bugfixes:
  - Fix the fragile test suite.  Works better if you have to crash it
    and restart. The major improvements are random usernames, and random
    keys.  Generate the keys in JavaScript, which is faster than doing so in
    gpg.

## 0.7.9 (2015-05-27)

Bugifxes:
  - Address https://github.com/keybase/keybase-issues/issues/1596
    - Via gpg-wrapper@1.0.5

## 0.7.8 (2015-04-24)

Bugfixes:
  - Add keybase installer as a dependency (PR #189 via @dtiersch)
  - Home fixes for Windows 10
  - New version of request
  - Upgrade gpg-wrapper for better Arch and GPG 2.1 support (v 1.0.4)
  - Upgrade request to 2.55.0 to solve proxy bugs (See keybase/keybase-issues#1397)
  - Add spotty to bundledDependences (see #193)

## 0.7.7 (2015-02-20)

Bugfixes:
  - Crasher for empty email addresses in PGP 
     - Close https://github.com/keybase/keybase-issues/issues/1398

## 0.7.6 (2015-02-19)

Bugfixes:
  - Case-insensitive email comparisons on self-signatures.

## 0.7.5 (2015-02-09)

Bugfixes:
  - Fix change in dns.resolveTxt introduced in Node v0.12
     - via keybase-proofs@2.0.13
     - Addresses https://github.com/keybase/keybase-issues#1362

## 0.7.4 (2015-02-06)

Bugfixes:
  - Bump to gpg-wrapper @1.0.3
  - Bump to proofs @2.0.3
  - FINALLY! fix the hang on pinentry bug via node-spotty to find our TTY

## 0.7.3 (2014-11-17)

Bugfixes:
   - Address #175
   - Address #178
   - Address https://github.com/keybase/keybase-issues/issues/824

## 0.7.2 (2014-09-23)

Bugfixes:

  - Allow `keybase verify` and `keybase dir verify` to work if you're not logged in
  - Fix regression in the `-o` flag for proofs.  See pull/172
  - Remove empty dir from SIGNED.md that showed up as a result of a testing bug

## 0.7.1 (2014-09-23)

Bugfixes:

  - Close #1038, a bug when posting signed BTC address first.
  - Address keybase/keybase-issues#1002
  - Puke on bad versions of node, and give useful errors

## 0.7.0 (2014-09-22)

Features:

  - Tor support; if you have a tor client running, specify config { tor : enabled : true }
    or -T on the command line to send http/https requests over TOR.
    - Will use the keybase hidden address
    - --tor-strict (or { tor : strict : true }) will be careful not to send
      any user-identifying information to the server.  It might cause some
      commands to half-fail or totally fail, depending.

## 0.6.2 (2014-09-19)

Feature:

  - You can use `twitter://maxtaco` anywhere where you used to use naked keybase names
     - Try with `id`, `track`, and `encrypt`

## 0.6.1 (2014-09-19)

Bugfixes/Improvements:

  - Overhaul assertions.
  - Close keybase/keybase-issues#{970,971,972}
  - Now you can make conjunctions via '&&' and disjunctions via '||'
  - Grammar now is "twitter://maxtaco" and not "twitter:maxtaco"
  - Parentheses also supported
  - Only one "--assert" arg needed (since conjunctions as above).
  - No warnings on unmatched proofs

## 0.6.0

Bugfixes:

  - Fix a crasher in `keybase config` with resetting values in the config file

Features:

  - Support XDG_CONFIG_DIR and friends for Linuxes.
    - Addresses keybase/keybase-issues#277
    - Addresses keybase/node-client#143
  - If you have a ~/.keybase directory, AND you don't have any XDG_* environment
    variables set, then the client should fallback to the old behavior, of storing
    all files in ~/.keybase.

## 0.5.1 (2014-08-28)

Features:

  - Upgrade to keybase-proofs@v1.1.0, for support of subkey signatures when they arrive.

## 0.5.0 (2014-08-28)

Features:

  - Support for versioned merkle leaves. Will be needed as we roll out semiprivate sigchains.

## 0.4.21 and 0.4.22 (2014-08-22)

  - Fix broken dep with bitcoyne/kbpgp

## 0.4.20 (2014-08-22)

Upgrades:

  - keybase-proofs@1.0.7, kbpgp@1.0.2, triplesec@3.0.19

Bugfixes:

  - Address bad regex for coinbase proofs
     - See keybase/keybase-issues#967

## 0.4.19 (2014-08-20)

Nit:

  - Hackernews shown in search results

## 0.4.18 (2014-08-18)

Bugfixes:

  - Fix crasher in `keybase list-signatures` where there are no sigs
      - Close keybase/keybase-issues#914

## 0.4.17 (2014-08-18)

Nits:

  - Remove experimental warning on dir sign/verify
  - Check HN users exist and have enough karma before letting them prove
     - via proofs@1.0.6

## 0.4.16 (2014-08-14)

Bugfixes:

  - Upgrade to proof@1.0.5 for HN fixes

## 0.4.15 (2014-08-11)

Bugfixes:

  - Proper U/A string for API calls to keybase.io
  - Upgrade to Proofs 1.0.4 for HN proofs

## 0.4.14 (2014-08-04)

Features:

  - HackerNews proofs

## 0.4.13 (2014-08-04)

Bufixes

  - fix bug in reddit proofs
    - Address: keybase-issues/issues/909

## 0.4.12 (2014-08-04)

Bugfixes:

  - Close #163: crasher when retracking someone who deleted a proof
  - Close keybase/keybase-issues#839 --- is self check was case sensitive
    and should not be
  - Close keybase/keybase-issues#834 --- double-revocation of sigs
    is a silent event, only shows up with --debug.

Features:

  - Coinbase support
  - Reddit support

## 0.4.11 (2014-06-24)

Bugfixes:

  - Upgrade bn, kbpgp and triplesec

## 0.4.10 (2014-06-24)

Bugfixes:

  - Fix documentation bug in `keybase pull` (see keybase/keybase-issues#811);
    Also, explicitly output (via log.info) which keys were pulled
  - Output which type of tracking happened (see keybase/keybase-issues#812)
  - More lenience in checking twitter proofs (see keybase/keybase-issues#822)

Security improvements:

  - Cache the last-fetched Merkle root block, to detect rollbacks...

Features:

  - `keybase announce` now allows arbitrary announcements (disabled feature for now...)

## 0.4.9 (2014-06-20)

Features:

  - `keybase update` now attempts to overwrite itself via the `--prefix` option to
    `keybase-installer`.  This is especially relevant for people who installed
    with the `--prefix` option to begin with...

## 0.4.8 (2014-06-19) [Forced-upgrade]

Bugfixes:

  - Fix broken package.json, introduced in 7fe003cbb4fae4328da67bdefa54d8ef8133c7c8
    Thank you @Fishrock123 for pointing it out.
  - Force upgrade to merkle-tree@0.0.10, to fix broken hash validations after we
    started to include prev_root in the root block.

## 0.4.7 (2014-06-12)

Tweaks:

  - Make input scheme more robust for revoke-sig
  - Close keybase/keybase-issues#771 -- a null @table bug in sigchain

## 0.4.6 (2014-06-12)

Bugfixes:

  - Don't include a `revoke : { sig_ids : [] }` stanza if we don't have to (via proofs@v0.0.35)
  - Don't say "one-way" under a BTC sig since that's confusing

## 0.4.5 (2014-06-12)

Features:

  - `keybase btc` support
  - Refactor of the table structure for signatures read out of signature chain
  - `keybase list-sigs` lists signatures in conveninent form, included revoked
    signatures
  - Get rid of `keybase revoke-proofs` in favor of `keybase revoke-sig`.

Bugfixes:

  - More debugging for people stuck in strange corners w/r/t revoking and updating
    failed proofs.
  - More restricted key flags on key generation; see keybase/keybase-issues#764

## 0.4.4 (2014-06-07)

Bugfixes

  - Address keybase/keybase-issues#732, again...
    - This time, proving also needs to see perm failures when decided to supersede.
  - Address keybase/keybase-issues#762
    - We missed a spot where verify needs a first arg (empty dictionary).

## 0.4.3 (2014-06-05)

Tweaks:

  - Better error mesasge for `keybase push --update` (see keybase/keybase-issues#758)

Features:

  - DNS proofs now work with either foo.com or _keybase.foo.com
     - See keybase/keybase-issues#750
     - Fix via upgrade to proofs v0.0.32

## 0.4.2 (2014-06-04)

Bugfixes:

  - In the previous release, there were errant references to `iced-coffee-script`
    in some compiled libraries.  Fix that and try again.

## 0.4.1 (2014-06-04)

Features:

  - Cascading upgrade to new ICS (v1.7.1-c), which doesn't depend on the ICS compiler
    at runtime.  This makes the package much smaller and strips dependencies.

Bugfixes:

  - Fix bugs in proof revocations
    - Close keybase/keybase-issues#675
    - Close keybase/keybase-issues#732

## 0.4.0 (2014-05-21)

Features:

  - Code & directory signing; try `keybase dir sign` or `keybase dir verify`
  - First self-signed dog-food, via `SIGNED.md` at top level

Bugfixes:

  - Multiple fixes in assertions
     - sometimes they weren't raising errors if they failed
     - DNS assertions didn't work
     - `--assert keybase:foobob` now works too

## 0.3.3 (2014-05-15)

Bugfixes:

  - Allow use of more features if no secret key is found.
    Addresses keybase/keybase-issues#693
  - Small grammar typo fixed (keybase/keybase-issues#703)
  - Establish a session before we load ourself, in all cases
  - Parse `-K --with-colons` better, look out for `ssb` (via gpg-wrapper@0.0.45)
    Address keybase/keybase-issues#689

## 0.3.2 (2014-04-29)

Features:

  - Report Twitter Permission denied errors back to the client.
    Address keybase/keybase-issues#661

## 0.3.1 (2014-04-29)

Bugfixes:

  - Upgrade to proofs@v0.0.26, for a more consistent merkle_root object in all signatures.
    Also fix the location for tracking signatures.  Also, include Client ID in all signatures.

## 0.3.0 (2014-04-28)

Features:

  - The client now checks the server's merkle tree, and verifies that the user's signature chain
    show up in the tree as expected.  If so, this state is signed along with tracking statements,
    so this way users are checking the server as they go.

Bugfixes:

  - Better error messages when network problems are encountered.
  - Fix bug with signatures dates not working in different locales
  - Address #157 -- Don't look for English GPG output in key generation
  - Address keybase/keybase-issues#649 -- mixed success/failure
    messges in the case of failed tracking.
  - Don't load the user's me object twice --- put it in a cache the
    first time, and fetch it out the second.

Cleanups:

  - Don't parse the direct output of GPG, rather, use the status FD mechanism.
    It would be nice to send status to Fd=3, but that won't work on windows.

## 0.2.21 (2014-04-11)

Bugfixes:

  - Address keybase/keybase-issues#568 -- better message for a needed update
  - Remove lingering nedb dependency

## 0.2.20 (2014-04-11)

Features:
  - Remove nedb dependency.  Replace it with our new iced-db, which is simply
    an FS-based key-value store.

Bugfixes:
  - Address keybase/keybase-issues#540 -- you couldn't open two instances of NEDB
    at once.  Our new iced-db is safe in this regard.
  - We weren't handling DNS proofs properly in checking tracks, so it was saying
    that users weren't tracked when they were. This isn't a security vul'n, it just
    made for a lot of extra prompting.
  - Handle bad invite codes with more grace
  - Clean up PW prompts (thanks to @RazerM)
  - Add better documentation for making DNS proofs

## 0.2.19 (2014-04-09)

Features:

  - Support for DNS proofs
  - Support for Web proofs at foo.com/keybase.txt

Bugfixes:

  - More workaround of double-CR-problem in windows.  Don't allow default y/n entry
  - Address keybase/keybase-issues#544, a bug in the key selector for keys that don't expire
  - UI tweak: indicate success after tracking succeeds

## 0.2.18 (2014-04-04)

Bugfixes:

  - Workaround double-CR-problem in windows

## 0.2.17 (2014-04-04)

Bugfixes:

  - Support spaces in windows usernames (and therefore homedirs)

Features:

  - keybase update now runs `keybase-installer` with a pretty reasonable set of opts, though not perfect.
      - Addresses keybase/keybase-issues#329

## 0.2.16 (2014-04-02)

Bugfixes:

  - Address bug introduced in 0.2.14, see keybase/keybase-issues#475
      - Upgrade to keybase-proofs@v0.0.21

## 0.2.15 (2014-04-02)

Bugfixes

  - Fix bugs in binary output, which was being Utf8-mangled and also supplemented with a newline.
     - Address keybase/keybase-issues#463
     - Address keybaes/keybase-issues#187
  - Fix broken regression tests that worked around this problemsm

## 0.2.14 (2014-04-02)

**SECURITY BUGFIX**

  - Sanity-check the server's proof text, in case it's cheating.  Check to make sure that the only
    plausible proof is the one that we made, and that others aren't coming along for the ride.
    This check comes via keybase-proofs @v0.0.20.

## 0.2.13 (2014-04-01)

Bugfixes:

  - Don't allow GPG passphrases with leading spaces, since gpg --gen-key in batch mode strips them :(

**SECURITY BUGFIX**

  - Don't show the GPG script used to generated keys when specifying `-d`, since it contains the users's password

## 0.2.12 (2014-04-01)

Bugfixes:

  - Allow "short" passwords on login

## 0.2.11 (2014-03-31)

Bugfixes:

  - Simplified error message for those who haven't signed their key

Features:

  - include client information in a tracking proof, so you can tell if you did it via CLI or Web site

## 0.2.10 (2014-03-30)

Bugfixes:

  - Republish with node-v0.10.26 and npm-v1.4.3

## 0.2.9 (2014-03-29)

Bugfixes:

  - Broken previous package didn't have gpg-wrapper

## 0.2.8 (2014-03-29)

Bugfixes:

  - Address keybase/keybase-issues#417 via upgrade to pgp-utils@v0.0.19

## 0.2.7 (2014-03-29)

**SECURITY BUGFIX**

  - The previous releases, v0.2.5 and v0.2.6, had broken verification for website proofs.
    Fixed with an upgrade to proofs v0.0.15

## 0.2.6 (2014-03-29)

Bugfixes:

  - Rerelease with slimmed-down package list

## 0.2.5 (2014-03-29)

Bugfixes:

  - Fix bugs in Github and Website proofs with MS-Dos encoding
    (via upgrade to Proofs v0.0.14).

## 0.2.4 (2014-03-29)

**SECURITY NOTICE**

  - This release was flawed since it did not pull it dependencies with it.

Bugfixes:

  - Vastly improved key-selection menu feature, which should be more resilient to weird
    GPG outputs that we weren't parsing properly.

## 0.2.3 (2014-03-28)

Bugfixes:

  - keybase/keybase-issues#407: Fix crashers with verifying userids on Website proofs

## 0.2.2 (2014-03-27)

Bugfixes:

  - Case-insensitive comparisons in proof checking
  - Remove some command aliases

## 0.2.1 (2014-03-27)

Features

  - `keybase help <cmd>` now works
  - `keybase prove` has a new -o option, for writing a proof out to a file

Bugfixes:

  - Better UI and documentation for `keybase revoke-proof` and `keybase prove`
  - Reduce code bloat due to certificates
  - fix a bad athrow in sigchains due to unknown proof types

## 0.2.0 (2014-03-26)

Features:

  - Generic website proofs

## 0.1.2 (2014-03-26)

Bugfixes:

  - add mkdirp back in :( nedb needs it

## 0.1.1 (2014-03-25)

Features:

  - Decrypt and verify say when the signature was generated. Thanks to @msjoinder for the patch.

Nits:

  - Wording changes in cancellation in revoke-proof
  - Remove dependency on mkdirp

## 0.1.0 (2014-03-25)

Features:

  - Address keybase/keybase-issues#112 --- Proof revocation from the client.
    This was a little bit of a hackjob, but we're going to change this all when
    we merge in the issue_137 branch.

Milestones:

  - v0.1.0

Bugfixes:

  - Address keybase/keybase-issues#332 --- Exit with return code 1 for no results found

## 0.0.44 (2014-03-23)

Bugfixes:

  - Fix previous bloated release
  - More synonyms for list-tracking

## 0.0.43 (2014-03-22)

Bugfixes:

  - Address keybase/keybase-issues#318, which was a bug introduced in the previous
    version.
  - Nail down our version numbers

Features:

  - keybase list-trackers
  - keybase search

## 0.0.42 (2014-03-21)

Bugfixes:

  - Disable colors everywhere with the -C/--no-colors flag
  - Address keybase/keybase-issues#315 by upgrading to keybase-proofs@v0.0.9

## 0.0.41 (2014-03-19)

Bugfixes:

 - Address keybase/keybase-issues#307: Upgrade to gpg-wrapper@v0.0.42

## 0.0.40 (2014-03-18)

Bugfixes:

  - We weren't hitting the cache on fingerprint_to_username lookups due to case incompatibilities.  Solve this with a sledgehammer; always convert lookups to lowercase.
  - Close keybase/keybase-issues#278 -- a broken error case that would have crashed anyways
  - More debug messages
  - More fixes for people who specify `primary-kerying` or `keyring` in the gpg.conf files.  Disable a few checks for them, and also pass --no-gpp-options through to gpg-wrapper

## 0.0.39 (2014-03-15)

Bugfixes:

  - Update to gpg-wrapper v0.0.40, to fix keybase/keybase-issues#190
    People who had `with-fingerprints` in their `gpg.conf` files were
    seeing broken behavior.
  - Fix bug in HKP loopback proxy. Change to "connection: close" instead
    of keep-alive.

## 0.0.38 (2014-03-13)

Bugfixes:

  - Update to gpg-wrapper v0.0.39, for solving issues with people who have a `secret-keyring`
    specified in their `gpg.conf` file. See keybase/keybase-issues#227.
  - Address keybase/keybase-issues#241: encryption works without meaningless error messages
    if you're not logged in.
  - Address keybase/keybase-issues#225: Sane error messages if you haven't even configured your
    client.

## 0.0.37 (2014-03-13)

Bugfixes:

  - Fix null pointer bug when warnings don't exist.
    See keybase/keybase-issues#234

## 0.0.36 (2014-03-12)

Bugfixes:

  - Recompile with smaller package, against released keybase-proofs@0.0.8, and not
    the local symlinked copy.

## 0.0.35 (2014-03-12)

**SECURITY BUGFIXES**

  - Don't mark keys as "ultimately trusted" as a consequence of encrypting
  - We effectively weren't using `hkps` before; we were sending requests for keys
    during verification over the clear.  We still verified the keys against keybase
    credentials, so the negative effects were limited.  However, now make `hkp` requests of
    a local loopback server, which talks HTTPs to the server and uses proxies as instructed.

Bugfixes:

  - Incorrect help text on keybase encrypt fixed.

Features:

  - Close #130: `keybase push --update` updates the current public key with new UID, subkey and
    signature information
  - Proxy external proof checks too.

## 0.0.34 (2014-03-11)

Features:

  - Support for https proxy servers via command line, config or environment variable

## 0.0.33 (2014-03-10)

Features:

  - Address keybase/keybase-issues#56: Allow '@keybaseio' prefix to tweets to reduce follower-noise
  - A nice animation when you generate a key
  - Instructions on what to do next when you signup

## 0.0.32 (2014-03-10)

Features:

  - Encourage users to add a new UID into their keys (Issue #122)
  - Support non-standard gpg-location like the installer

## 0.0.31 (2014-03-03)

Bugfixes:

  - Don't print secret stdin input to GPG when using -d.  We got away with it since
    node's buffer class only printed the first 20 or so bytes of a buffer, which were
    luckily boilerplate header, but don't take a risk.  See #116.

Cleanups:

  - Address issue #115, cleanup tracking, don't reimport the key into 1-shot rings, like
    crazy, use a QuarantinedKeyRing instead.  Upgrade to gpg-wrapper@0.0.37 for this.

Features:

  - Allow assertions in `keybase id`

## 0.0.30 (2014-02-28)

Bugfixes:

  - Ignore proofs marked as "permanent failures" &c by the server (see keybase/keybase-issues#69)
  - Address keybase/keybase-issues#74: don't import our own secret key into the temporary key
    ring since we're no longer signing their key via gpg.  There is a bigger simplification
    available, which will be open as issue #115.

## 0.0.29 (2014-02-28)

Bugfixes:

  - Checks and X's on windows, since UTF8 doesn't work
  - Only warn once that an upgrade is needed
  - Don't reject 16+ character github names (keybase/keybase-issues#64)
  - Allow selection of DSA-keys in keyselector (keybase/keybase-issues#61)

## 0.0.28 (2014-02-27)

Bugfixes:

  - Address #112 --- make automatic secret key pulls standard in a bunch of places, like
    decryption, signing, tracking, etc.
  - Fix a bunch of different corner cases in key pulling
  - We broke tracking and proof uploads in 0.0.26. After a key revocation, the end of the
    sigchain was effectively null, but the server rejects such a chain; we still need to link
    to the last link of the previous key.
  - Redact contents of session file in -d to guard people's secrets if they post them to a
    discussion thread.
  - Fix decryption/verification of a signcrypted message, breaking on node v0.10.0 due
    to a bug in libuv.  Plausible workaround in iced-spawn v0.0.5

## 0.0.27 (2014-02-26)

Bugfixes:

  - Fix keybase/keybase-issues#41 --- sigchains failing to verify on an empty chain

## 0.0.26 (2014-02-26)

Bugfixes:

  - Fix bug in sigchain verification; only look at the tail links that also have the same
    fingerprint as the currenlty active key.
  - Actually honor the --no-key-pull flag to login

## 0.0.25 (2014-02-26)

Bugfixes:

  - Fix key selection bug when the keyring is empty.
    See keybase/keybase-installer#37

Features:

  - Enhance the login experience; pull keys automatically.  Not a complete fix,
    but on the way to fixing it.  See the following two issue reports:

    - keybase/keybase-installer#34
    - keybase/node-client#111

Notes:

  - We never pushed this release live, we jumped to v0.0.26

## 0.0.24 (2014-02-25)

Bugfixes:

  - Workaround bug in Node v0.11.1+ in reading X509 certs

## 0.0.23 (2014-02-25)

Bugfixes:

  - Close keybase/keybase-issues#29 -- keys with null emails in their userids

## 0.0.22 (2014-02-24)

Bugfixes:

  - Be a bit more clear as to how to post a gist or a tweet.

Features:

  - A debug feature:`keybase config --server http://localhost:3000/`
  - Can push a secret key without pushing a public key.

## 0.0.21 (2014-02-21)

Bugfixes:

  - More work on keybase/keybase-issues#19 ; case-insensitivity

## 0.0.20 (2014-02-21)

Bugfixes:

  - Fix keybase/node-client#106, that '\r's on windows were basing PGP block parsing
  - Update for new github gist URLs, which now can be at githubusercontent.com
    (see keybase/keybase-issues#19)

## 0.0.19 (2014-02-20)

Bugfixes:

  - Fix a crash in keybase id, which was crashing on failed key proofs.

## 0.0.18 (2014-02-20)

Features:

  - DSA and ElGamal are now working; not as well-tested as RSA, so rocky road ahead

Bugfixes:

  - Upgrade to gpg-wrapper 0.0.33; better error-reporting, rather than the abstruse "error exit 2"

## 0.0.17 (2014-02-18)

Bugfixes:

  - Close #96: better error messaging was all that was needed to solve the pickle in which people uploaded an unsigned public key to the web site and then had commant line problems.
  - Close #94: Signcrypting now works, even for yourself.

## 0.0.16 (2014-02-18)

Bugfixes:

  - Fix bug on Windows with wrong home environment variable.

## 0.0.15 (2014-02-18)

Bugfixes:

  - Close #83 and #85: the experience of tracking and id'ing users who don't have any proofs posted.
  - Close #93: We were allowing non-self-signed keys through

Features:

  - #90: Better debug messages on startup to help debug peoples' weird problems

## 0.0.14 (2014-02-17)

Bugfixes:

  - Close #88, fix the bug with encryption & signing.

## 0.0.13 (2014-02-17)

Bugfixes:

  - Some remaining references to the streams in gpg-wrapper were around, clean them out.

## 0.0.12 (2014-02-17)

Bugfixes:

  - Upgrade to gpg-wrapper v0.0.30, to fix bug in gpg.set_log (which wasn't there)

Features:

  - You can now join the waitlist from the command-line client; sorry, this might be
	considered a bug....

## 0.0.11 (2014-02-17)

Bugfixes:

  - Close #86: sqlite3 dependency, see below
  - Progress on #81: Windows support.  We'll need to reassess after this release how well we're doing.

Features:

  - Switch from Sqlite3 to NEDB. This is better for portability, but might be a performance hit.

## 0.0.10 (2014-02-14)

Bugfixes:

   - Issue #82: A regression from the previous release, in which we weren't asking properly for
   remote tracking.  Hopefully this fixes it, but it's quite fussy

## 0.0.8 (2014-02-14)

Bugfixes:

  - Add UID and username into config.json on successful login, if it's not there (Issue #78 & #79)
  - Use session.get_uid() and not env().get_uid() for proofs, which should be more robust (Issue #78 & #79)
  - Some services weren't logging in, so add logins for them (Issue #78 & #79)
  - Upgrade to gpg-wrapper v0.0.25, for less dependence on parsing GPG text output.

## 0.0.7

Bugfixes:

  - Downgrade SQLite to v2.1.15, which still works with Arch linux (hopefully?)
  but doesn't fetch code remotely.  Turns out v2.2.0 is doing that via node-pre-gyp,
  which is therefore breaking the security of the install process.
  - Fix regression tests to handle lack of dummy invitation code.

## 0.0.6

Bugfixes:

  - Remove dummy invitation code
  - Upgrade SQLite dependency to v2.2.0; there were reported breaks with v2.1.19 on
  Arch Linux.

Tweaks:

  - Regenerate all files with IcedCoffeeScript v1.7.1-a

## 0.0.5 (2014-02-13)

Bugfixes:

  - Error out if you try to track yourself
  - But you can encrypt for yourself, special-case that in the encryption subcommand
  - Close #77: we were being too conservative in determining if a track of another
  user was still "fresh".  It is now considering fresh if you're signed the tail
  of their chain (as before), or if you've signed the last non-revoke, non-prove,
  event.  In other words, we can skip over "track"/"untrack" events in their chain.

Features:

  - Inaugural changelog

