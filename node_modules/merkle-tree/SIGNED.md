##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTpIh4AAoJEJgKPw0B/gTfV1MH/AmZwDVndFBsJ8h3HUVHs9gb
Py58UWpupZ90d/B7X99izEHjyG2iGd6clSIbKjMoUPS0Qs4aE3EywSpYAIEshCGw
tu7hktjear4ov6icoLA9OLMrm2oSrT80vvolWKafqOSE1YaXZnDSQ/KSZIdIdP/t
AVWlT2U6kXtjm+UItFaawveeySHgL6CG/ZInxyls5kNU6tRz663xPXtpLxEAOOG0
feqpbC/ud7Cb+b8GXfojY73NTwpLHXKrvW0sAPdMKdvAan7qe16rGKquNo3NQ0rX
NybXzFKomqC7vafXHxyZgbpYBgWzasv3ipim9tQuUNwX2cWZqMBre0foyLIgyvU=
=vRHQ
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                     contents                                                        
             ./                                                                                       
547            .gitignore             a3260451040bdf523be635eac16d28044d0064c4e8c4c444b0a49b9258851bec
399            CHANGELOG.md           f970b7038eda8e721cf87590d1467bb729e204c8cc9f0b5ab4dc24f8e8bf60b3
1482           LICENSE                9395652c11696e9a59ba0eac2e2cb744546b11f9a858997a02701ca91068d867
393            Makefile               069be562c87112459ea09e88b442355fb08ffdbacb38c9acc35f688f7bc75e09
67             README.md              45eb09507031120206ab8d1463725c822b60d6109fd2e34eadf792e81917a292
               lib/                                                                                   
299              main.js              40ca05af21bfbdfe551411d5c492aaeb8d405ae11055875c1bcdf474edd62b9f
1932             mem.js               c23ce8608a17e23371e52b3b80e87441e93bcd802b11f8ea7493e259d22f8543
33324            tree.js              ad52f7fc1754647a1e747b34c35ce749cc4a5a7137fb645b16241698fe22924b
838            package.json           a21a3a826e8ef9249c05f6ab90b8680744af622abe8276bd6ccd2898fd7b8085
               src/                                                                                   
104              main.iced            f52112db1bdab29276374d4f4d39eab83c1b0a8db2955dc0e23aadbfb43d4b47
1011             mem.iced             f4f664a2e82498a312f59a6ae72caf3a5e4cc136be7967e88398e44f6b8de34b
10590            tree.iced            6056a33f87cebd1e7d6cd2e6442e01c51855bd4e0bd3dc551a7fa28b032ae6e3
               test/                                                                                  
                 files/                                                                               
2118               0_simple.iced      5ecbf097a879d9aacf951511b7c2a81e8d405c13704df4d7cd56baaf2aeb2660
1987               1_bushy.iced       a49b51258e8973ba358cf5e2fae8b66ca6b6a18f2635b97d09c75604a026cb21
1779               2_one_by_one.iced  7bb8910e8dedbc46454f76904379f9dbfcb75ffd9af56be67f97967409da086d
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