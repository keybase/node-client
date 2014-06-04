##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTjzMyAAoJEJgKPw0B/gTfLx0IALafUMekx6uqCk09Cdmk9YO1
C3fCPAvJIwXjUa1D8EdXt+nWTWO8QJ4+gAI1eAAf095npOw39pYukm8UQXP2D+fE
QuX0WS5Gd78L2U8Tx7+5csyWnKgugMoBxK4P2xaClB1WWDdV0PNk7ULM7IfSUE8S
aa9zMMoEHqA0tkCViYecGnlPHhdKIT3VHVPkunXH479/ZUxQ1FA/iuWgXz2vqGg1
COoxrXs18XW49Wp6niynCAcEBgL8sXXaXxsw/C4G3gI1Q7ofcvJlF9LSwn2Vf3zb
8W3/RHzrhqh4paQF6gJmprOSErlW+/VshzD46fGYB4uo3jl18GXi4lTAjz1WNmk=
=O0Gp
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
5549            main.js     ecb92f6bccbff6564652806cf4e4027946b79e9ca84dd628696c8f6b73f98196
618           package.json  27e5539c07ade19c3ed990abc946449b781298f1439373ae9f77181141238b85
              src/                                                                          
2599            main.iced   c3b748111db7c34e5ab84797438f80e47b573e597254287f34635e944a0a912f
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