##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJVWea5AAoJEJgKPw0B/gTfmOsH/1npWV+odUl/uqrHWW5zvI0Q
NWLnQsnPIkMbmATmIH9ixH23RHASKEEbZbgS05/UmumxM+uv+PbMCxO0LCrDvDy5
YtSQU4gmrUMwokWRbSrM7V0uGe31mH7GYcBzk5Tl4julbIU6ySLfiZzGcEEVn+vI
7RPcUMqz4aJih2/CPNY6jQVhyCpH0+H6E6V9UgFraNzcH7rekZzN2AVDxKFLGUOG
mtox8ypxzpzIYjHtAr4Kf3aMrVnainTR9eEjX4VQ9C/SJJdVh5PV8YEzxqyLKv+u
xNUowEyGc0SYRTdfI8UlV7a9UHHtWu092SuGCHUILgZdcDZGHYoVfv7CSgdi2pI=
=jKmO
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size    exec  file                contents                                                        
              ./                                                                                  
46              .gitignore        e446248bb7d6e5c58234de6c127ee27687b1d84304f84bd5f368b4280b0e92db
1475            LICENSE           f8bc12c174a5377c5d2e96c2a9c419ff7b608459bb7615fc305661eca155384d
1135            Makefile          949e832fcffda80cc6f45c8e7e977a08485fc84a5e0ee83ac0edad4582da3426
94              README.md         6d45790af19c47d5b2df93405a8a78179913860177841171e1224ed897120f06
                lib/                                                                              
936               base.js         32741386a25d562b714b247078c916ed925b7209495a76c164bac0e99d24eed5
1183              main.js         40ce98ce2c8dae28cf56ec50c574509c71661bafa9efee70d2be2f85a9436d20
2067              sodium.js       49c3469abd276df579e045ccc17c49253630b3e9e26b73e88ed9eec692f209f5
2075              tweetnacl.js    d4da18bf492da3e923890b04659d7c672d0971ec028d9bb7ecca8ec1ea0aa8a1
645               util.js         be2846c96d0fdcd07dd96c86fcb529af94e09ba8d9110ee6b47d433fbef2a963
793             package.json      dffc9b05f4bc6835e7194c9cff2966ecf6b873e99bf9fc886d2d15362ca7631d
                src/                                                                              
1400              base.iced       71a5c89cb57ff4bc1964910d987f1d914ff9f02e3058438c6a660040024c7530
1300              main.iced       2f08f4899cf1193c1370c63257be2cd32fc1aacd0a0039074bfb917da983111a
1828              sodium.iced     6147b59cc4c0b015b9b5e1eb3340e30bfc232a9aacd1cb4b1b1380b36cb3e733
2019              tweetnacl.iced  4f845affac187a3b01eccadf33494f8a10a3aa7b013456f976afd6219c097703
376               util.iced       8ae5f3a21f115c41d4ac72420d945cde81683d8690094a440d6dd00572fc7755
                test/                                                                             
                  browser/                                                                        
287                 index.html    e31387cfd94034901e89af59f0ad29a3e2f494eb7269f1806e757be21b3cf33e
193                 main.iced     ba58653bd3407fbaf8237ec01c61668fb0c567d113eed01fb862e946a39000de
673230              test.js       87f00dae5064138dd0aca2d469577d0773b1d68fd25fcced0117fb4185d640b3
                  files/                                                                          
2320                0_sigs.iced   f980c55498dafccb45bc3ebe5af21d7be46c110cbec022fe2eda9d46e192760e
52                run.iced        8e58458d6f5d0973dbb15d096e5366492add708f3123812b8e65d49a685de71c
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