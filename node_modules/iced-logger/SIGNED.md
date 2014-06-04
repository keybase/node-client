##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTje7bAAoJEJgKPw0B/gTf2XUH/ify9gcpGpWFV00rL3hHaY8S
Uh/KTZQ6J3kSGGqynb+Igf6p8/4JR5y+myNjtFkYV5dSdu/kR3mQAxV+nEQGSLUi
AsBunuWGbXlnAOPRkkdw6i/DJVaokfMptouMyQzNkMLKK1yIXv4tVRPYwRbDxL8f
8zQQe31/py5LvVleH72s01vS1h1nU0VPlHzC4zsEcJtQ94We5GdXGgThubw3PkzG
r76RCGCOUgXbSVnYYeuDojIKWKLhqG4jvZH4yx4AuWmVdywLxzY8spiPblCTPAe6
5FdvuUzj9VRl00ERmWukCJXkcGPPdSINvdVZN7ruMiWzvOyz8Z6WRBEtZGZO2jg=
=VpLR
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size  exec  file            contents                                                        
            ./                                                                              
109           .gitignore    ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
1489          LICENSE       1e933ceb3f4a00ae33672d4e344f9ff26e92bc8f34bc0c7a52fd0ef257607858
296           Makefile      bbcf957dce2d62b7bb7e767b69e97c22a1118896e3eccd2061d465127eeb5a86
85            README.md     6bac611fa0fdfd8a5a2e4ea5a1f974f0f037589c66d2209721171b300a8cdba0
2849          index.iced    cc102caeba23e25be63378ca161c4587835cf245c98e6780444da99493031da3
5143          index.js      f214a61b3c64a9414f259fd457f70c961f465a1793b82fe4ef03b3886b5a5dc4
508           package.json  02e4f51ec92673abfd1567af4e39ff66fba1130bd596c362913f66ce86d17970
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