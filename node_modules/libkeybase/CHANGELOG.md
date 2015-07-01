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
