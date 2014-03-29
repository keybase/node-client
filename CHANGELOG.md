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

