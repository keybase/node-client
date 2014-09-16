##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUGKQgAAoJEJgKPw0B/gTfHAkIAJP71Z+Swp6T5U9PLkIaBb7J
Gytq0i9oryAsX0roUe3COGMu49vcMM26Zx3TveM3ysGkaoKGiygNrHHzq740eE1O
flJsTd9Zg3auKUNt6LmUl4blVw/4gJlm7zzuDm9eEuvzFbfp8WlqvOaG7ZCk7L6e
Rqj5CeGZdKjNj8CvuaQNxaJI6E7tZ6QRm6HpyB7hjxHLuRoj2+/MpwAHJGaymvZg
I9SGKgkDr998x5UvokdP/Gc6HIBRr1llDhrdTGkpVMSQ/B7Zq8fhoutAZXEwv5hm
XtADIMnjC2dtnVqei5y1r/4jaqdH1LdgARgyuwXo9N8Ih8VtGtNhWbKeeFTPLOo=
=+kLt
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size  exec  file            contents                                                        
            ./                                                                              
547           .gitignore    a3260451040bdf523be635eac16d28044d0064c4e8c4c444b0a49b9258851bec
1482          LICENSE       9395652c11696e9a59ba0eac2e2cb744546b11f9a858997a02701ca91068d867
334           Makefile      46ef2af0d44ee236eaee20196dd2301b83e55517d3a163abdc5e9e40a8b0c0f3
57            README.md     eba23a2d29ac9116c43978735933bee668cc87c8e6dbe7314a706025f5086fa8
              lib/                                                                          
6890            main.js     d3ca79e67b58ed407d9bf82f26d739b0f8f1308554383f4f64ae0bad69bfe1e4
681           package.json  39873f045f0194f1f88242cf73f5debce8bad81a5435db172ac353dfcf2f4e49
              src/                                                                          
3537            main.iced   51739ceb878e4f26d2f0d613416c1b4d0d4c36250624884595ed5bebf431e3d6
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