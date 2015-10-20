## 1.2.22 (2015-10-20)

Bugfix:
  - Fix bugs related to detecting sigchain resets.

## 1.2.21 (2015-10-05)

Bugfix:
  - Ignore broken reverse-sigs (https://github.com/keybase/libkeybase-js/issues/5)

## 1.2.20 (2015-09-21)

Bugfix:
  - missing dependency in package.json
  - callback accidentally called twice in error case
Enhancement
 - Simplified fix for 15 Sep 2015 bug.  There's only one case to consider.

## 1.2.19 (2015-09-18)

Bugfix:
  - Workaround keybase/keybase-issues#1765 signature corruption

## 1.2.18 (2015-09-11)

Feature:
  - Respect PGP key hashes in the sigchain.

## 1.2.17 (2015-08-13)

Changes:
  - Merge userids when merging PGP keys.

## 1.2.16 (2015-08-05)

Changes:
  - A new assertion type for sig_seqnos

## 1.2.15 (2015-07-25)

Changes:
  - Update kbpgp, use merge_public_omitting_revokes().

## 1.2.14 (2015-07-25)

Bugfix:
  - Merge PGP primary keys via kbpgp @v2.0.33
    - Close keybase/keybase-issues#1707

## 1.2.13 (2015-07-21)

Features:
  - Add logging to sigchain replays.

## 1.2.12 (2015-07-06)

Bugfix:
  - Move to kbpgp v2.0.27 w/ subkey merging to handle zaher's sigchain

## 1.2.11 (2015-07-06)

Bugfix:
  - Fix for zaher's sigchain, deal with multiple PGP uploads to recover
    removed subkeys
  
## 1.2.10 (2015-07-05)

Bugfix:
  - Remove debugging from the previous

## 1.2.9 (2015-07-05)

Bugfix:
  - Workaround for bad username -> UID conversion
   - Fixes: keybase/keybase#1655

## 1.2.8 (2015-07-03)

Bugfix:
  - Fix to the proceeding, in which opts weren't properly passed.

## 1.2.7 (2015-07-03)

Bugfixes:
  - Allow key time_travel, so that we can check prior states in which
    subkeys might still have been valid (though now they're expired).

## 1.2.6 (2015-07-02)

Bugfixes:
  - Case-insensitive username comparisons (keybase/keybase-issues#1654)

## 1.2.5 (2015-07-02)

Features:
  - Add a debug counter to track the number of unboxes we do.

## 1.2.4 (2015-07-01)

Bugfixes:
  - Don't use Buffer.equals(), since it doesn't work on Node < 0.12.0;
    Use the paranoid bufeq_secure anyways.

## 1.2.3 (2015-07-01)

Bugfixes:
  - Make keybase-test-vectors a dev dependency only.

## 1.2.2 (2015-07-01)

Features:
  - New version of kbpgp.

## 1.2.1 (2015-07-01)

Bugfixes:
  - Stop using server ctime at all. Sometimes the server is wrong.

## 1.2.0 (2015-06-23)

Features:
  - Change the sigchain interface to make mistakes less likely.

## 1.1.7 (2015-06-23)

Oops, I forgot to update the CHANGELOG for a while there.

Features:
  - A full sigchain implementation.
  - A shared test suite in keybase-test-vectors.

## 1.0.2 (2015-04-21)

Features:
  - Eldest_kid is now 3rd (0-indexed) slot in top-level array
  - If we add more slots to "triples" in the future, they can
    take any form.
  - Complete test coverage of Merkle leaf decoding

## 0.0.6 (2014-09-19)

Features:

  - Expose more parsing innards, to be used from the node-client command line

## 0.0.5 (2014-09-19)

Bugfixes:

  - Throw an error on assertions that can't possibly be useful.

## 0.0.4 (2014-09-19)

Bugfixes:
 
  - Better error checking for assertions (and hopefully better error messages)

## 0.0.3 (2014-09-19)

Features:

  - New flexible assertion language support; we're going to change the client to incorporate it.
