##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTj0EUAAoJEJgKPw0B/gTfpoUH/iAgZVMwsh70xf0OCdOVJWrK
7BI3VR4v62y4zTl+bjHRcZI8r5K00Yf+nTGIIzPyic0O6lg/VQPO1FU7Q3eQGg5p
g0ZyTUovnryapoIJCZYjSskr8zXvGt6gPKF1cQ+0YHRp68pI9PDepEgw90EbDu89
SBguN5seueIJw5RMn2IdPCOAjw+3vPDNI/KdVgwARaACcA2OOjDxNu/9PFxsV+0b
twwG0ZDxGeTaAU3wfxvug1fKDqjEwAhnd2U+W4wDJyBqua1xWAF4cIDNY3DjGc74
DZ8quZGVR0PyhiqFstIx8OS+tUVkgxJHHVp6EOOfHj7cWfSTfBxMDUjjKmU0mA8=
=QQ7t
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size  exec  file                contents                                                        
            ./                                                                                  
107           .gitignore        f5c3f45c2ad04fe63c9365f970a37b27d39ed721b71e889ff8f2b610143a7905
1074          LICENSE           a431ce5edcc96f2047072de28425e99163465d8ac0484b6cf54a9aa55231a16e
217           Makefile          6721d873ee6a7d80da5d8d1df66bfdf3f8365396bad705c13683ef95979a984a
3596          README.md         59a50463a5fb6fa3904532001c9190cc4ec9a9e12e456f287b096ec78d015202
              lib/                                                                              
5698            generator.js    e958adddfedd4e92e8778670d01323085a14abef3f16fc7212abf7f366b3e3e4
132             main.js         6db8bf9163e15abaf89a4af5b50afa2fd0f1a552adc94f069a6c1d393fc9fd79
632           package.json      e0a86aa1c1fac02c17e5087ca033d5cd9b3c98138fac16ea98da5ed61271ab7a
              src/                                                                              
2078            generator.iced  68ae5500546c6fa7570361fb8ff60d50e85d965c761f5a4307ad477f9020aaeb
57              main.iced       a246ca8c283f8023ae8379262178664ed69399b06307c9832b3993243e7296c5
              test/                                                                             
129             test.iced       63f498807580e02536ca665c3b48dae6080388420ad410417d05aa172ef95b55
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