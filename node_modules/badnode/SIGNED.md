##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUIXSnAAoJEJgKPw0B/gTfXlIIAKS5UGsYit3R4TOsCOkUUEoj
9yXGGPWafZnmtLFXkvViT/kincpjf873B+Q/Iq37jEXadxhJcv8wS1GqhOUdkKbt
SODVnvSjwcFbq1xXd2779rzw2Alg63pVMsEN0UXRsFYAWsBHk17ra/Je2tygQsr/
cHRux/nyz9vLXxUNUCnHgKRr6DDV9g9s4V9oDdXg/qOFH0jaK5fdbPSrPKbLuH7e
oO/iKHBNCWLCdkh7qxQVYfHoVrqbdhu4m3YlxNsJrJdOkkvGS3pAA0B34EPfl2zb
KHjXjDa5rnnPCu83m2fqAEBUipPtqAoEnYxWPzMIOAZXKyNHVyuNmzje30WcuMo=
=M+1n
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size  exec  file                  contents                                                        
            ./                                                                                    
587           .gitignore          abcbd5929ba2d059647bd4c6c99a74df2676bfbaaf44535e4713b53fbd14e6a8
1473          LICENSE             d0560411ddd7937e8b87d85c290c0445bd9c390aa485eeac7f838e56e7598d95
244           Makefile            7d397680c94d1b5ec2436610beb8dd4f27586306210920e31981449157824fd1
64            README.md           076d41de237604bcc439602fc664111cf6db55550759e2d7af4b00388fbc8143
924           index.iced          ad88b40b8519413ab132caa403327740829216b3eb29f59ddb94662c90ae791c
1627          index.js            9ea58e70c4670f9d9c0684c95359bc43101e2550ccaf31b69188f5ab3d147f12
658           package.json        a9fdbd59a98b4c0f7381d450ef4b97281d2e88b51a54eedba2c634a7ae6f6e45
              test/                                                                               
                files/                                                                            
538               0_badnode.iced  0c437564f590b6783ab7fecf676985f3297d751804e8fe24c89d91f9db4ec7bb
183             run.iced          822568debeae702ca4d1f3026896d78b2d426e960d77cb3c374da059ef09f9fd
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