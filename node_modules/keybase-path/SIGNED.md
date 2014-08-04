##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJT39HAAAoJEJgKPw0B/gTfyDUH/2Gkk/fkgpBBYy7md/qgdven
dHwwzfXvp+WOEZcDRFhRva4ly7RQJHFF0a6zY3qdBBOQ3D4yE7BFmlrpqS8yLhqJ
Im63rA+Ny+NOzQggYh93nDI3P62g7pQttk8vTQbiRRFMkl+AVtk5AUg0pvbo7Tiq
twgzj840jxhDdNc7WwMf/n6PBOgWpgwEr/0MdPQdgRyI0jQcgnqsPbOalxEP+pAV
LTyT2FgC0yx+WlT7umy3+2twJCxf8TDnTHXGAQbAXBlGROXZBFiLha5XQrXPDmNG
l1v9bikZSyYjlHXx+zj8EwEAifs591rwkLTWlXCVPRSQeXqmkebMcAGYaXKIaLw=
=YoU1
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
6476            main.js     9ee24589dc7e93cdb69c5f03b4d03fd63057b026bc67f7eedafd7e91a6b2433d
681           package.json  3f5fb0763bc1368743534e890779eba2981370255bbfee7fe511fc11fcc16bba
              src/                                                                          
2980            main.iced   70c60de6075843c7c08edb9a985dd1a15e07f1042f20400bf25e0260ec3dace1
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