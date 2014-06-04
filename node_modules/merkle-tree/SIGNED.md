##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTjzcmAAoJEJgKPw0B/gTfv7QIAKFLawJwyF3Jv8pWY0xPfj8E
uMmuQDTNS3GR05xct0L7HaSSkhPapp7v6lPfXgAQBCRHoW85vLvUWXGv8l47K9Gg
EvqbzQItV15qEqspTOrDddje+Pwqj1p5f+Rhvr7xDe9W2uwFjckNKlZwe8v6SAHU
UIcjwlu3RTYR+n5nIo4vXULxv39eqlYDAK51n6I5JWx1DBQ0EyMmYEZE4MFnf+jQ
h1vMcmso62LV2MXNKS36slg4+vuxTtthLEk5+fC/EUgzvAyr5zDQrX6bCzxYKQ5F
KG8WJO9ex+A46mi+dtAnu8Q1ng0/dFesS39zrMP+Vmz9ztoXTJdJsgsu5rtdeVc=
=RqbG
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                     contents                                                        
             ./                                                                                       
547            .gitignore             a3260451040bdf523be635eac16d28044d0064c4e8c4c444b0a49b9258851bec
157            CHANGELOG.md           65ddf3cd17e88d1b23867159be7e453d811e29e9a05ec815947eb34c6b388291
1482           LICENSE                9395652c11696e9a59ba0eac2e2cb744546b11f9a858997a02701ca91068d867
393            Makefile               069be562c87112459ea09e88b442355fb08ffdbacb38c9acc35f688f7bc75e09
67             README.md              45eb09507031120206ab8d1463725c822b60d6109fd2e34eadf792e81917a292
               lib/                                                                                   
299              main.js              40ca05af21bfbdfe551411d5c492aaeb8d405ae11055875c1bcdf474edd62b9f
1835             mem.js               cd14dcbcdd312d7e29459153c89553285fbd16319a605445b7b4fdb3c3552f17
31271            tree.js              660de7f58d4edb164a9494c8929b582232fd226fb757ce7f48bc2ab5a27a391d
835            package.json           c6f84d533e5d797e437019435cc86b82b08d55d1d18167b5c574c333a45dfaad
               src/                                                                                   
104              main.iced            f52112db1bdab29276374d4f4d39eab83c1b0a8db2955dc0e23aadbfb43d4b47
947              mem.iced             69b5c0440fd3e319da4a4a76eb91b5f1db002515d060e6b5441c58930d706c97
9414             tree.iced            e663a51ec6595781cd0170603bdc77434dadacfba336d3c88025fe8013ec88bc
               test/                                                                                  
                 files/                                                                               
2103               0_simple.iced      c326c17c3a4447a96c8c82ea9fb95032b2a06e101a3acb5e571253924c45747a
1987               1_bushy.iced       a49b51258e8973ba358cf5e2fae8b66ca6b6a18f2635b97d09c75604a026cb21
1459               2_one_by_one.iced  8e529356d6b7a9ff1d8e56a7930f2f20d41a63e9a3f2812e232f8ddf1882453a
690                obj_factory.iced   ceddef906435b35a9ff0436b8900bb8b92d036e0d24222e10d62c933c3d7e47e
53               run.iced             79bcb89528719181cafeb611d8b4fdfa6b3e92959099cbb4becd2a23640d38df
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

<!-- summarize version = 0.0.8 -->

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