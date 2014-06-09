##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTkjYjAAoJEJgKPw0B/gTfXU0H/A47L3PgTZ88VKwMiHXrunJu
NAgt+oxZL21/Z450QWnF3bckWtDOJ+1QO35xWyRwLnTTM5BD7xIAM3yEPF73SkiV
6M5YzfaaJLx/dUYhKQLkXtrE0S1wgbCw15aX57vTmVURD5q979l4DBWczVnCHp0T
xl8Ajyaf1HtO2hq9fvzdlt/NBFbRP74888aC9mymD18FP9R/IsmwlwEVfT5tBKEa
6Im4HrVSlQuVxHq+acGoLqLHeRQp0GJ/7A6MMPQ+Osum09y+5NMIZlcZj6nIPWgt
LU/bCL3C4YBeBH9XRHFk6SnNytsdIqVS5PBKRBkClYgoPKmrRt0JpCXPwgv4MHw=
=wCUF
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size  exec  file              contents                                                        
            ./                                                                                
109           .gitignore      ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
109           CHANGELOG.md    55c5871e30439542be17fc6f8e43acf178b6450bae6fdfb36f002e5dd4290357
1483          LICENSE         333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
414           Makefile        3fc373da860330bca19decdb3649c59d78ce19476a55585d93aba3f4681d2636
91            README.md       9bb4d8d39fabc12e85959613a2e93a28f33d0df82fdc5edd39caef80a1b46dcc
              lib/                                                                            
1048            address.js    d6b782f9b70c9096d1442f2532e001736e5163e173f3a08d88d15304697dbeed
113             main.js       a5324b09b89f993deefae933e8352c8750732ea1c68d9959cce7d58ddb1999a6
832           package.json    791a1163ff9782aec3beb5f13fb39969a9de2c1ec279277697e018d14e51414b
              src/                                                                            
499             address.iced  49b86faa3214ea4b3774f98038de7beef7f4ca0023cc5c1208cb88d45bfcb10d
38              main.iced     795b67a4f1763d0ce0c878132d71f3bb7516a369d8f3c4b0dc1750dc18914765
              test/                                                                           
                files/                                                                        
1                 0.iced      01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b
169             run.iced      70ef38fc04a9ee264e2317e5b4dcb00a69a996139e98b5d9e34d0ffa16609479
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