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

