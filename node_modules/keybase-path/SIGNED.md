##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUGIUKAAoJEJgKPw0B/gTff1IH/1TvI/mrpef17g8lNkhSclCF
gCITdcg/vJr3xxJ0Yrb4jgOka9QjDPGH+CX2HJ7js+H5b9NJaKSihwAoHzo2tEwV
jqmbU6pXA+02f9S7ev/O1YMNkQ1BLvWo/4P98VZhPv0pux3z8fDKF8EcKhCf3GfC
xbZZ7kWob8/RD+k34c63fQ5RO+R2BmcRnuvbYos0B89Z0ZAodNsHVh/VEVSwWkQu
jTZMlfTAcYT3hUbNiQhFmY1pjFtfOTBKJiZXWchQ6KWmlqlJn3+NYuepJJVIfY0E
n68W6x20YsJ/ra+/+8+YzWlttf6FwFbpgNV6Gg5z7HAXt3nD3YCRBaF6MnyEVTM=
=hLky
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size  exec  file            contents                                                        
            ./                                                                              
547           .gitignore    a3260451040bdf523be635eac16d28044d0064c4e8c4c444b0a49b9258851bec
1482          LICENSE       9395652c11696e9a59ba0eac2e2cb744546b11f9a858997a02701ca91068d867
334           Makefile      46ef2af0d44ee236eaee20196dd2301b83e55517d3a163abdc5e9e40a8b0c0f3
57            README.md     eba23a2d29ac9116c43978735933bee668cc87c8e6dbe7314a706025f5086fa8
              lib/                                                                          
6629            main.js     0ae2b16748cfe092cd582ce18f0c0159c4bd145038c790d4d0e2914ac072aac2
681           package.json  95aafd3d3963566860ff648396ff1f753eb8ae2ddb2ecc2e3ee5d0af37866a05
              src/                                                                          
3382            main.iced   2d5620517fbaab786596f396a2fba00341239918a6aff9baaf40e6f802b34d3e
```

#### Ignore

```
/SIGNED.md
```

#### Presets

```
git      # ignore .git and anything as described by .gitignore files
dropbox  # ignore .dropbox-cache and other Dropbox-related files    
kb       # ignore anything as described by .kbignore files          
```

<!-- summarize version = 0.0.9 -->

### End signed statement

<hr>

#### Notes

With keybase you can sign any directory's contents, whether it's a git repo,
source code distribution, or a personal documents folder. It aims to replace the drudgery of:

  1. comparing a zipped file to a detached statement
  2. downloading a public key
  3. confirming it is in fact the author's by reviewing public statements they've made, using it

All in one simple command:

```bash
keybase dir verify
```

There are lots of options, including assertions for automating your checks.

For more info, check out https://keybase.io/docs/command_line/code_signing