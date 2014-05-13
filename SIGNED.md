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

iQIcBAABCgAGBQJTcjIjAAoJENIkQTsc+mSQVB0P/RGduh/wUhP1fHOnOhp5lVoG
WA09T8AScxzXyYlCbVBwMV0rdEPOFxTIZUfi3ZYMV4sWgGdCprXwWzOBrFkkxxNO
sVHF5rxrfWIBmG0FniLuaeTer3x5hV4kgg1jozMJnlaEWWUhVi2Tr1smWE151IyR
DnFpBSPnvtdUcf1XhIGkeiKI4NOSc3ChXZ/JWyWc2MYWjNvxRdXDlofXmpecK6++
oI2JMwjgghIL0M90HEa4EEN+NMkYv2ks6u/9rn3FBLe0hhOwsnYOEH6Ix50FVJH+
edCEzoNJWfsuY22W7x/mHmOhTNa0PV8zeEA3iRQ8kRs/ANOY4CJ3B8rDdUod965C
cdjHz4F+S5yf0SRgwpJuzcwxhC36e46sQYI28CM8EKzCr7XWodNr4sC0PetVSWlQ
h0DSbtLfpG3afmb4zz/MVNUlFYnrGrxAWGK4E5BD1+JCfDseHVJ799U5DlSOf4Nt
CLUAEWvwBjp80npEib5otSYQ8tZE8LSSeUFykXccX6B1aSEd4srL1oKzAquf2W4D
chOg6HiiDDhzSSRGvqNRq/Yso3IL+93dJ2ZJIVMzopbd4na1jWZ0svFDeqKzu3NQ
WFw/QBHZNegAhLSYsOR/ZchD4iNYpd675QqRjKu3kncn2K9v+tks9Fg92tLnfr/E
i35JbHZmv2Q073bBfm6x
=GhRE
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
