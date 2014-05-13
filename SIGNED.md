#### Verify

```
size    exec  file                    contents                                                        
              ./                                                                                      
224614          node_root_certs.json  83de1ef6b6c776c4e9dc81af4666d77b83938e3364b9940f80a82645fab87257
```

#### Presets

```
git      # ignore anything as described by .gitignore files     
dropbox  # ignore .dropbox-cache and other Dropbox-related files
kb       # ignore anything as described by .kbignore files      
```

#### Ignore

```

```

<!-- summarize version = 0.0.4 -->

<!-- BEGIN SIGNATURES -->
#### Signed by https://keybase.io/chris
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQIcBAABCgAGBQJTcjMwAAoJENIkQTsc+mSQCmQQAJ3AvMhxBG6X6qbsCTRQ7b7J
HJWyC+B2e/4h/XQMbxL3bSQTqL0qZwA5lsVrST+6MDIzIpS2LDRtNwNvWxapQ+YH
eHS1sCsIVrGhKnkbvBMDUUsmiGjtR9kF/J5yrR4mPuUitAebYfs0rH32JpKiK0sk
HzAnFEJyU6gFViB729E4wbaB6v52nNZGHyppbP1/Z6Nyi9eFzVzcsd3dndcjutxr
djCwsCv3Tbm0zP35nq8/FH08TD3uTR7inqfBtP//n9aP9kJksgU3ucdSTqvr4WDk
3e70KeC8GzlT9tZlq7f6u415rvCOfLC0VAVJV/cxudro48+ed6BzhSHMH/2LOUa3
e8OHyQdyJ9O01SaJrgdbVUQt/In9Y4g2Ms8sbRnTDyEzlQt5lzeNRaHxK0hwNj6v
HaDL9l0WYk3HG3tQd1wyPEZDMP1e9pu0XFl7KNmvmaDmmp74nooBuZm9Yudg/Cld
L+hhRnOMXuAb+6GXyaUthlrO6v2CPN6d0e1KGRTiTFjJHMFKkWSRgxuNunTroV1X
UpWDMQOXp+EZM9U1qCsv4aidgrk0k7ES1QoBccptw8aFdBxpSrRrey2DsLiaShPS
JxruSirDbG77TjozHNhVBWnKtKxA64rW2HUrKeLlkhzTQtzzmz2ls0kqnzctbGO0
9R7ANwQYVjSWpPgNDjbO
=ouu7
-----END PGP SIGNATURE-----
```
<!-- END SIGNATURES -->

<hr>

#### Using this file

Keybase code-signing allows you to sign any directory's contents, whether it's a git repository,
distributable zip file, or a personal documents folder. It aims to replace the drudgery of:

  1. comparing a zipped file to a detached statement
  2. downloading a public key
  3. confirming it is in fact the author's by reviewing public statements they've made, using it

All in one simple command:

```bash
keybase code-sign verify
```
There are lots of options, including assertions (for automating your checks).

For more info, check out https://keybase.io/_/code-signing .
