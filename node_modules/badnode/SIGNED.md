##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUIWzUAAoJEJgKPw0B/gTfIf0IAKE94RAeEHcUV+YCJxF2NxV5
5ZzaOfidBQ6OdNc1Yc4vzQh7FumbmNPMuMGf8LTZmg+xpMGX7A18irtCqIQ2Lonk
UABm2rgLa4xom+XSZh4707MivQIyj+hm23UfQ8V2Z8/H6QxeSUzh1u8yA7il0zbg
jVZDD/wVGk9qqLcxbWFmv5Eg3iik8wbhMiixV4VeraLDyPruaqHwZl6NoZleQrld
u4fJf9LzNfwU+zRzgEcdtLh0uInAbxSpBMF/k4AnK/RuE2LcMrq2iyCwqrrC1thO
YIYssPNqNRJgYZpqBY+GPjzXaX0z2MnxLGIXJGx3w6JQ8q7bKFWuxmgZ8sTGyDs=
=coPd
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
928           index.iced          383d0c391e0cf0c251826c407c0adc535a16ddce7b19e5f10c3cb6463a925694
1634          index.js            5afd05c7051a197faaf771a6a85310b2af045ecb46e2e5c339016e1954f35fdb
659           package.json        0c315e11df4bd9fcba72a43c4aa434dc5e39c4f790b7644ee4d3ce7ecc567d1e
              test/                                                                               
                files/                                                                            
489               0_badnode.iced  483998b8da79ddc688f52aa503e6270b34f260d20b5199ce523ce10a94b2b3bf
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