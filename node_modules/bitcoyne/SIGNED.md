##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1

iQEcBAABAgAGBQJTlkOOAAoJEJgKPw0B/gTfFWUH/RwsyAiU3VEleSBCQwxLa1yZ
XPUgKUVGIeq5ZzGzJRgHj6uvV+ijGX3mtvrGoGeKMv+neurJKvwvNIVV0E90Sd6T
p2cv5QT/yZ3sERsltYohp0TXAq/7VGGNTpWAw4kF5Rp00pFn4J5YHm1Pj1Nn58ir
/OzJoz+Ow2XM+oRbghDr/5wCWmikBFu79fvmL/bV9RaO/ve0V7WePNK5StLenOcI
ucr3MtBRPVhmewUZ8tTjbcwF+1AteMUTFmV6XZoFRPMFzZc3pwJWHKH9tOdmc2yQ
8r/hDzWSnAq0tV9MYPuCHHxgdVNQ/RRKeSkYeuuMu92Bu0iGbjPd5m+cUZ2WInI=
=cu7V
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size  exec  file                        contents                                                        
            ./                                                                                          
109           .gitignore                ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
208           CHANGELOG.md              a11f193664cce903b2a30b0eb22bde1800c70db14987c719c05efa03e5cb6c5d
1483          LICENSE                   333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
414           Makefile                  3fc373da860330bca19decdb3649c59d78ce19476a55585d93aba3f4681d2636
91            README.md                 9bb4d8d39fabc12e85959613a2e93a28f33d0df82fdc5edd39caef80a1b46dcc
              lib/                                                                                      
1343            address.js              6eac2c746ef1eed9933ff4f1f24a070fb837f68af5bca75b3600483923e33649
113             main.js                 a5324b09b89f993deefae933e8352c8750732ea1c68d9959cce7d58ddb1999a6
832           package.json              086f312d8763f1ae0d2aefc81c1af5a897bbd99290f27f98df6ff2bd9d1d5256
              src/                                                                                      
913             address.iced            ad19ee95d74a058d3746315a8c9814303ec7546e35b382e861dfd9dba927d70a
38              main.iced               795b67a4f1763d0ce0c878132d71f3bb7516a369d8f3c4b0dc1750dc18914765
              test/                                                                                     
                files/                                                                                  
999               0_address_check.iced  c43f7592db25d676a4370a7b7a20d2673fd8b812c97020adfe8d1e19fbc941cf
183             run.iced                822568debeae702ca4d1f3026896d78b2d426e960d77cb3c374da059ef09f9fd
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