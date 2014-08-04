## 1.0.0 (2014-08-04)

  - Arbitrarily cut a 1.0.0 release
  - Use the correct UserAgent format
    - closes keybase/keybase-proofs#899 
  - Reddit proofs
  - Coinbase proofs
  - Factor out some common code, but more work to go on this.

## 0.0.39  (2014-07-17)

  - More twitter API stuff

## 0.0.38 (2014-07-17)

Features:

  - twitter API calls to get follower_ids friend_ids

## 0.0.37 (2014-06-24)

Features:

  - ws_normalize in Twitter proofs.  Address keybase/keybase-issues#822

## 0.0.36 (2014-06-23)

Features:

  - Support for announcements

## 0.0.35 (2014-06-11)

Bugfix:

  - Don't include a `revoke : { sig_ids : [] }` stanza if we don't need it

## 0.0.34 (2014-06-10)

Bugfixes:

  - Fix a bug with revocation in which we weren't providing a default
    argument to _json(), which was crashing the proof generation.

## 0.0.33 (2014-06-09)

Features:

  - Add support for cryptocurrencies
  - Allow any signature to revoke previous signatures

## 0.0.32 (2014-06-05)

Features:

  - foo.com OR _keybase.foo.com are valid DNS TXT entries now...

## 0.0.30 and 0.0.31 (2014-06-04)

  - Recompile for ICS v1.7.1-c

## 0.0.29 (2014-05-15)

Bugfixes:

  - Better debug for keybase/keybase-issues#689

## 0.0.28 (2014-05-08)

Bufixes:

  - Address keybase/keybase-issues#695, don't hard-fail if .well-known is 403.

## 0.0.27 (2014-04-29)

Bugfixes:

  - Interpet HTTP 401 and 403 as permission denied errors

## 0.0.26 (2014-04-28)

Features:

  - Add merkle_root for all signatures

## 0.0.25 (2014-04-10)

Bugfixes:

  - Remove iced-utils dependency

## 0.0.24 (2014-04-09)

Features:

  - Support for DNS proofs
  - Support for foo.com/keybase.txt

## 0.0.23 (2014-04-05)

Bugfix:

  - Ensure that ctime and expire_in both exist.

## 0.0.22 (2014-04-02)

Bugfix:

  - Be more careful about timeouts

## 0.0.21 (2014-04-02)

Bugfix:

  - Error in the previous release, we need to allow some slack before the proof due to GPG
    client comments that might appear part of the signature block.

## 0.0.20 (2014-04-02)

Features:

  - Add the ability to sanity check the server's proof text

## 0.0.19 (2014-03-31)

Features:

  - Add Base::proof_type_str which just does a lookup against the lookup table

## 0.0.18 (2014-03-31)

Bugfixes:

  - Strip out debugging output

## 0.0.17 (2014-03-31)

Features:

  - Include some client information in proofs

## 0.0.16 (2014-03-29)

Features:

  - Add a new "generic_binding" type of proof/signature checker, which will happily
    check username/key against any proof signed by that user, which contains the user's
    username and UID.

## 0.0.15 (2014-03-29)

*SECURITY BUGFIXES*

  - Regression in last night's bugfix that let any proof go through in website proofs.

## 0.0.14 (2014-03-28)

Bugfixes:

  - Ignore DOS "\r"s in Website and Github proofs
  - Do a better "existing" check for Websites, which was broken.

## 0.0.13 (2014-03-27)

Bugfixes:

  - more case insensitivity

## 0.0.12 (2014-03-27)

Bugfixes:

  - Case-insensitive username checks

## 0.0.11 (2014-03-27)

Features:

  - Extra safety check for IDNs; if node's url module breaks, we'll throw an error
  - New 'resource_id()' for remote key proof objects.

## 0.0.10 (2014-03-26)

Features:
 
  - Prove you own a website

## 0.0.9 (2014-03-26)

Bugfixes:

  - Handle twitter usernames that are numbers

## 0.0.8 (2014-03-11)

Features:

  - Allow proxy'ing of scraper calls
  - Allow for ca's to be specified, useful when using a self-signed proxy above.

## 0.0.7 (2014-03-10)

Bugfixes:

 - Loosen up checking for twitter proofs, allow @-prefixing.
 - Better debug logging flexibility, and a cleanup

## 0.0.6 (2014-03-09)

Bugfixes:

 - Twitter proofs were broken, with hunt v hunt2

## 0.0.5

Features:

  - Add debugging for proofs that are inexplicably failing.
  - Inaugural changelog
