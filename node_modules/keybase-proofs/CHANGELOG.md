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
