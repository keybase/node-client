
## 0.0.5

Bugfixes:

  - Error out if you try to track yourself
  - But you can encrypt for yourself, special-case that in the encryption subcommand
  - Close #77: we were being too conservative in determining if a track of another 
    user was still "fresh".  It is now considering fresh if you're signed the tail
    of their chain (as before), or if you've signed the last non-revoke, non-prove,
    event.  In other words, we can skip over "track"/"untrack" events in their chain.

Features:
  
  - Inaugural changelog

