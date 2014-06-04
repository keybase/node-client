##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1

iQEcBAABAgAGBQJTj6cGAAoJEJgKPw0B/gTfZqQIAJPmmrjapQs+mbIkczHn/GY5
G8/m2+tMhkb/9Bg/wbSer6BnnFmYf2YS9FK5F9ZVFa7WfksTCHe5UbrWAfIIMpXQ
RKZhuVXkAAmKOTxh6dO4qXrg+FYuLXHCmrp4eWtYwOqt/2GSA2wkN1L079e79l1M
YTmkJz7oylobwRREJ+fpI+tDFcVlD66QU9VOge57B1XGwnFR9AuQMABHoLyi+pQL
DXL9oU84NvjgNoIP3fqHykSTUbGE7JMxirZe1vQj8611ySiY6Uh5FdGLztCOIJaj
csi8DzFW6KtA2Lh9UDEPwPtlcXuX/pE7LcTZcACcIc/G2Cwk59VG/iZ8r5Bgjb0=
=XTf1
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file            contents                                                        
             ./                                                                              
13             .gitignore    16d30e4462189fb14dd611bdb708c510630c576a1f35b9383e89a4352da36c97
206            Makefile      fe36113d39382362b2118a18b836d4a35c091cebf4b96449765ce33341cc0bc2
93             README.md     d0f2182a445e9d2d096307c0cf9c729f553e059a15e1208158ea38ae27c3499d
7638           index.iced    6e0f10fd646831cc683ebb111e561f21123f1dfaf7d389cd16a9ff0dc1b6d29f
25907          index.js      46afd306cd256022919b3d092d60fe8c5ef81bd91550d34aabb2fe9566d6285c
12237          index.map     b85c15a376ac3fb97754292710c98a821baf5051686e672975122ad968b5d3bf
609            package.json  df4c71f30f003fea9ec74611748f5e2d3c20ee1d2378521c20b8fd8587bba968
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