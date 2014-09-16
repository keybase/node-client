##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUGJFnAAoJEJgKPw0B/gTfOoQH/00+Ik4eXVfRX4tZ+5iwK5T+
zsW1syp6OnzN/xhZqgAWXYE5kVljl9Bqdgt+f7dEmWKLHjD1cUyX7E/prsyVrUUM
DwApv/+fZo3UpS7MDk81IbyWZyzKk0dhfs2EOlA5vZhU4xJ+Wz28KJwO//Jf12Qz
g3tOqakY8ZtcsSQhJFEd04t75p2zD34hWnvr8qobeSQTyH8puoEzoXG/HJ94dzbp
5L43rVpGJhB/00oVhUQjL9vx58du8kfJ5AH3ebsOMpQbhuWsLDpsGmyKd4EICFL3
DLPVJ9b7W6xKANqVDi6KDmnzm+iqZ7BqDBOUH0F8gPDfJJO9JB4IaOIsNPaH6T0=
=mkU0
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
6784            main.js     d908ed9d4d7759e3bb7c8c73d32a9b6d61cad979b963942b98ccb6c2e5a93f67
681           package.json  5286376b64b36b5956a14af11c9e542473c17dd483de5af2876a212e8c27a44c
              src/                                                                          
3451            main.iced   057d8efb245c75e30d0ce286e39f83ee77f2db3e84f55e835d2c8820ecacfd39
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