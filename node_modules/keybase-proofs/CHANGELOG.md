## 2.0.46 (2015-11-24)

Bugfixes:
  - Fix regressions in reddit proofs (missing _check_api_url function)

## 2.0.45 (2015-11-24)

Bugfixes:
  - Workaround new coinbase HTML style

## 2.0.44 (2015-09-25)

Features:
  - Bitbucket support (thanks to @mark-adams)
  - Allow 0-time expirations in sig gens

## 2.0.43 (2015-09-15)

Bugfix:
  - Unbreak the site, don't return our trimed JSON

## 2.0.42 (2015-09-15)

Bugfix:
  - Disregard trailing whitespace in JSON when checking for non-acceptable
    characters and strict-mode byte-for-byte comparison

## 2.0.41 (2015-09-10)

Enhancement:
  - Strict JSON checking

## 2.0.40 (2015-09-08)

Enhancement:
  * Use kbpgp to generate PGP key hashes

## 2.0.39 (2015-08-20)

Bugfix:
  * Fix a crash when generating `eldest` links.

## 2.0.38 (2015-08-20)

Bugfix:
  * `pgp_update` links now put PGP key metadata in a separate stanza instead of the `key` stanza.
  * PGP keys' fingerprints are validated now.

## 2.0.37 (2015-08-17)

Bugfix:
  * `pgp_update` links now take a dedicated KeyManager for the PGP key being updated

## 2.0.36 (2015-08-13)

Retired feature:
  * Strip out dualkey, they never made it into the wild

Feature:
  * Sigs which add PGP keys now include a hash of the armored key
  * Add a new sig type for updating PGP keys which also includes the full hash

## 2.0.35 (2015-08-12)

Bugfix:
  * Sometimes we just want a generic chainlink; in that case, don't worry about
    checking optional sections against the link-specific whitelist.

## 2.0.34 (2015-08-12)

Enhancement:
  * Add better error messages when invalid sections are found

## 2.0.33 (2015-08-06)

Fix embarrassment:
 * Rename internal methods in SubkeyBase to be more sensible

## 2.0.32 (2015-08-06)

Bugfix:
  * Update `eldest` and `revoke` statements to have an optional `device` section.

## 2.0.31 (2015-08-06)

Feature:
  * Each sigtype now has required and optional sections of the `body`. If there are `sections` in the body not that don't correspond to the sigtype, it will now be considered invalid.

Bugfix:
  * Update auth sigs to put `nonce` and `session` in `body.auth` instead of `body` directly.

## 2.0.30 (2015-07-24)

Bugfix:
  * Initially find Reddit proofs by looking at the user's submissions, not by scraping /r/KeybaseProofs

## 2.0.29 (2015-07-24)

Bugfix:
  * Bugfix in the previous, handle empty TXT lookups too

## 2.0.28 (2015-07-23)

Feature:
  * Allow third-party DNS library, so we can interoperate
    with broken Node v0.12 DNS TXT resolver: https://github.com/joyent/node/issues/9285

## 2.0.27 (2015-07-22)

Bugfixes:
  * For dualkey sigtype

## 2.0.26 (2015-07-21)

Bugfixes:
 * Fix crasher with reddit scraping

## 2.0.25

Security upgrade:
  * Require reverse sigs for sibkey

Features:
  * Allow dual sibkey/subkey provisioning, useful for single-transaction workflow in passphrase update.

## 2.0.24 (2015-06-15)

Features:
  * Allow update of passphrase via signed statement

## 2.0.23 (2015-05-15)

Features:
  - Allow an expanded lookup table of proof types, for testing purposes.

## 2.0.22 (2015-05-11)

Features:
  - Expose some hidden base classes for testing purposes.

## 2.0.21 (2015-05-06)

Features:
  - Allow `expire_in` for signatures
  - Allow passing `ctime` in for signatures, and actually use it
  - Add a `reverse_sig_check` method to Subkey that we can call directly.

## 2.0.20 (2015-04-03)

Bugfixes:
  - Allow revocation of keys via key-ids in sig links

## 2.0.19 (2015-03-24)

Bugfixes:
  - remove debug code
  - Cache the ctime on sig generation so that if we call @json()
    twice in the case of reverse sigs, we'll get the same blob both
    times.
Features:
  - pass back the reverse signature payload in sibkey signatures
  - Expand upon reverse sig; do it over the whole JSON object.

## 2.0.18 (2015-03-19)

Nit:
 - s/parent/delegated_by/.  This is a better name.

## 2.0.17 (2015-03-18)

Features:
  - Expanded reverse key signatures, and renamed fields.  This might
    break existing test data!

## 2.0.16 (2015-03-18)

Feature:
  - Use KMI.can_sign() and not KMI.get_keypair()?.can_sign()
    Only works in KBPGP v2.0.9 and above.

## 2.0.15 (2015-02-11)

Feature:
  - New sigchain link type: eldest, for your self-signed eldest key.
    It's synonymous with web_service_binding.keybase but
    should only happen at the start of a sigchain.

## 2.0.14 (2015-02-10)

Tweaks:
  - Session object in pubkey login

## 2.0.13 (2015-02-09)

Bugfixes:
  - the return format of dns.resolveTxt changed in Node v0.12.0;
    workaround it with this fix.  Should still work for earlier nodes.

## 2.0.12 (2015-01-30)

Tweaks:
  - Explicit parent_kid for subkeys

## 2.0.11 (2015-01-29)

Tweaks:
  - Strict reverse sig handling

## 2.0.10 (2015-01-29)

Security tweak:
  - Sign a more descriptive reverse-key signature

## 2.0.9 (2015-01-29)

Scraper tweak
  - Be more liberal about generic web sites; allow raw '\r's
    as line-ends

## 2.0.8 (2015-01-29)

Change:
 - move device up one level in the JSON structure

## 2.0.7 (2015-01-28)

Additions:
  - The 'device' signature

## 2.0.6 (2015-01-27)

Tweaks:
  - rename desc to device

## 2.0.5 (2015-01-18)

Tweaks:
   - Sibkey and subkey signatures have a "desc" field for description,
     not a "notes field"

## 2.0.4 (2015-01-14)

Bugfix with the previous fix

## 2.0.3 (2015-01-14)

Bugfixes:
  - Sometimes kids() can't be computed

## 2.0.2 (2015-01-14)

Features:
  - Sign `eldest_kid` into key blocks (Issue #15)

## 2.0.1 (2014-12-22)

Bufixes
  - Various

## 2.0.0 (2014-12-10)

Bugfix:
  - All @veganstraightedge to use his twitter handle (>15 chars)

New features:
  - lots of architectural improvements for keybase/keybase#204
    - Use either PGP or KB-style packets, sigs, and keys in all places.

## 1.1.3 (2014-09-21)

Nits:

  - Error message for cloudflare

## 1.1.2 (2014-09-20)

Bugfixes:

  - Make a better coinbase warning...

## 1.1.1 (2014-09-20)

Features:

  - Say if it is tor-safe or not. DNS and HTTP are not...

## 1.1.0 (2014-08-28)

Features:

  - New proof types for subkeys (think delegated app keys).
  - Begin to work in private sequences (need a separate type for those)

Bugfixes:

  - robustify _check_ids, and don't crash if short_id or id is null.

## 1.0.7 (2014-08-21)

Bugfixes:

  - Allow '0's in coinbase names. Thanks to @dtiersch for the PR.

## 1.0.6 (2014-08-18)

  - Yet more HackerNews fixes; only allow a proof posting if we can lookup their karma.
    For dummy users, the JSON endpoint will yield null, which means they won't be able to
    show their profile, either

## 1.0.5 (2014-08-14)

  - More HN fixes --- don't normalize usernames with toLowerCase();
    also warn that it's slow.

## 1.0.4 (2014-08-11)

  - Use the FireBase.io API for hackernews

## 1.0.3 (2014-08-05)

  - Hackernews logins are case-sensitive?
     - See here for more details: https://news.ycombinator.com/item?id=6963550
     - Resolves keybase/keybase-issues#911

## 1.0.2 (2014-08-04)

  - Bugfix for an HN failure with the command-line

## 1.0.1 (2014-08-04)

  - HackerNews

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
