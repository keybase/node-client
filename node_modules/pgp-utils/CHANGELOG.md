## 0.0.19 (2014-03-29)

Bugfixes:

  - Allow userIDs with no space between the name and userid.

## 0.0.18 (2014-03-17)

Bugfixes:

  - Workaround a bug in browserify; seems like spaces in the middle of base64-decoding
    yields the wrong answer on a decode.  Works fine in node.

## 0.0.17 (2014-03-17)

Bugfixes:

  - Close #3: handle newlines and spaces at the end of a message block

## 0.0.16 

  - Better bufeq_secure, which does not use floating point math
  - Make the decoder more robust for messages that have spurious whitespace
    See keybase/keybase-issues#219

## 0.0.14 (2014-2-21)

Bugfixes:

  - Fix line splitting on windows, have to split on \r?\n.
    See keybase/node-client#106

Features:

  - Inaugural changelog
