## 1.0.5 (2015-05-27)

Bugfixes:
  - Trim trailing/leading whitespace when verifying sig payloads

## 1.0.4 (2015-04-15)

Bugfixes:
  - Disable use of options file for any one-shot verifications

## 1.0.3 (2015-02-06)

Feature:
  - Lookup TTY and init pinentry

## 1.0.2 (2015-01-14)

Bugfixes:
  - Complete the new KeyManager interface; implemented get_ekid()
    with a stub for now.

## 1.0.1 (2014-11-17)

Bugfixes:
  - Parse revoked keys in output
    - Support for https://github.com/keybase/node-client/pull/179

## 1.0.0 (2014-09-23)

Features:

  - Address keybase/keybase-isssues#1002 and look for gpg2 first.
  - Also bump to a release version, this software is pretty mature by now.

## 0.0.46 and 0.0.47 (2014-06-05)

Features:

  - Version upgrades and ICS v1.7.1-c upgrade

## 0.0.45 (2014-05-15)

Bugfixes:

  - Fix bug in Indexing, wasn't properly looking for `ssb`s
    Add new test case for the above. Note that we need to supply `--with-fingerprint`
    twice to get gpg to output fingerprints for subkeys

## 0.0.44 (2014-03-29)

Bugfixes:
  - Simplify read_uids_from_key, and use the Index system
  - Upgrade to pgp-utils@v0.0.19 to get more lax parsing

## 0.0.43 (2014-03-28)

Features:

  - index2 which also has the ability to index secret keys and use a query

## 0.0.42 (2014-03-20)

Bugfixes:

  - Close #5: Write an empty trust DB.

## 0.0.41 (2014-03-17)

Features:

  - We probably should not call this a feature, but introduce the 
    "nuclear" option for dealing with fussy gpg.conf files.  Just
    ignore it for temporary keyrings.  Only on if you specify it.

## 0.0.40 (2014-03-15)

Bugfixes:

  - Address #4.  Fix Indexing for people who have `with-fingerprint` in their 
    `gpg.conf` files.
  - Fix bugs with parsing columns from `gpg --with-colons` output.  We were
    mangling dates and also key id 64s

## 0.0.39 (2014-03-09)

Bugfixes:

  - Better support for users with `secret-keyring` off on an external device. In practice,
    this means that we have to touch the temporary `secring.gpg` before we can import to it,
    a constraint which isn't enforced if `secret-keyring` isn't specified in the `gpg.conf` file.
    See issue keybase/keybase-issues#227

## 0.0.38 (2014-03-09)

Features:

  - Better support for non-standard GPG

## 0.0.37 (2014-03-03)

Features:

  - Do not print secret keys to stderr in debug
  - New `QuarantinedKeyRing` type that corresponds to incoming public keys that are
    not yet kosher.

## 0.0.36 (2014-02-27)

Bugfixes:
  
  - Export armored PGP data, we were forgetting to do so in a couple of cases.
  - Use the iced-spawn@0.0.5 workaround to closing stdin bug on node 0.10.x

## 0.0.35 (2014-02-26)

Features:

  - When loading keys, store all UIDs, not just the first, in the in-memory argument

## 0.0.34 (2014-02-25)

Bugfixes:

  - Upgrade to pgp-utils v0.0.15 to allow null emails

## 0.0.33 (2014-02-20)

Features :
 
  - If quiet is on, and there's an error, we'll pass stderr back via the Error object.

## 0.0.32 (2014-02-18)

Bugfixes:

  - More robust and secure file-touching mechanism for new Alt primary key dirs

## 0.0.31 (2014-02-18)

Bugfixes:

  - Issues with Alt primary dirs on windows being created for the first time.

## 0.0.30 (2014-02-17)

Bugfixes:

  - We dropped set_log a while ago, when we moved spawn functionality into iced-spawn.  So add it back.

## 0.0.29 (2014-02-17)

Bugfixes

  - More windows testing bugfixes

## 0.0.28 (2014-02-16)

Features:

  - New indexing system; can read in the whole keychain with -k and then access the index in memory (close issue #3)
  - Small tweaks and features additions for new keybase-node-installer version


## 0.0.27 (2014-02-15)

Bugfixes:

  - Upgrade to `iced-spawn` for all spawning work.
  - Fix bugs in windows

## 0.0.25 (2014-02-14)

Bugfixes:
  
  - `verify_sig` now goes through `one_shot_verify` which should ease the dependence on our ability to parse the text output of GPG

Features:

  - Inaugural CHANGELOG.md
