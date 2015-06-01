##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJU3iLhAAoJEJgKPw0B/gTfY3QIAI1N1zHftcBgf5IDlqLgidoi
jBOFtXLLSpn6VIlIqIvgb/jPE2orkMi9fQ+ydf1w77LysTWaRYIUmkDljayjcA48
aMuYB8n6LHcSEIH3yQHhKCyG8vrarJJ47lHai3f7af12+owZEZgo7OoX49tHtfBK
vXeLsrnMhW+w18spLgWTxpAM/Kqlm/xbNWwgpde6h1CuwYgEydc3i6y4b+X/Fpeo
W1k3sd/Vu89wOz3RT+czBlVC9GDifFyAG//eZxum86ZmwnpcGKVRNGRO4mFaNazw
rabsdZx7Tc16yUL8SU0F5Ah9SiAZzLuTO6r+nj1E6xz7vTnI22divAfkYyvhRWE=
=PWTH
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                     contents                                                        
             ./                                                                                       
547            .gitignore             a3260451040bdf523be635eac16d28044d0064c4e8c4c444b0a49b9258851bec
624            CHANGELOG.md           7031de48cb3660d020d12d51a73cb0fdc3e25ffe728c0a53a468af607bade679
1482           LICENSE                9395652c11696e9a59ba0eac2e2cb744546b11f9a858997a02701ca91068d867
393            Makefile               069be562c87112459ea09e88b442355fb08ffdbacb38c9acc35f688f7bc75e09
3629           README.md              73a273ed77aee98d6dd9820f6c57e3eeb2241bce77b2e0a8dde2c554549b8941
               lib/                                                                                   
299              main.js              40ca05af21bfbdfe551411d5c492aaeb8d405ae11055875c1bcdf474edd62b9f
1932             mem.js               c23ce8608a17e23371e52b3b80e87441e93bcd802b11f8ea7493e259d22f8543
33337            tree.js              29ebef75c8ab727857deaba2120b38e55b94d336eb51cfab988e4e66ba0cca70
838            package.json           e59cd5ef84507ee6121eea6b7a166824a6a6d0709ed333c26f086e4c2509393d
               src/                                                                                   
104              main.iced            f52112db1bdab29276374d4f4d39eab83c1b0a8db2955dc0e23aadbfb43d4b47
1011             mem.iced             f4f664a2e82498a312f59a6ae72caf3a5e4cc136be7967e88398e44f6b8de34b
10540            tree.iced            6eade86028b1608aee6f91544c6caae625ebdaae54fda37557046b96f321b689
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