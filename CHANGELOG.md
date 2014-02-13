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

