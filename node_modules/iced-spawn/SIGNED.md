##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTjfYfAAoJEJgKPw0B/gTfzKgH/1q04L8ipjn9D/sVddY4eDv6
HAfOmPZTzbBU6OKNvuKCrn4q3nR6Jxx3yxEQvNleoYrmTiMMHZUBq881YlQ0OT7a
9enPZudnlKplC65CFcARvoX5hfpbI57q62wo7KWEbEw67jHyOt82PeM6LuQzfFUZ
OOepSJ0pGgmzivkp2+2NcaOlBpYcDy/u5JPq0H0FlVwrDqsbi/9URjlU7fC4DAyq
EKFPG1F2BLemJdoyEyxfTX1F3WCl+hOFs8GX4aR1khMJV6II7/D7yFfXmSMY8NHJ
LojrZ7eWjdJtqAqdd9EZdBEEoVVy6xNtB9a6r1J5dw9D7cxzJTQZEOMDKxBfFWM=
=VpJa
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                    contents                                                        
             ./                                                                                      
109            .gitignore            ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
1017           CHANGELOG.md          2b9b7d7c59bffbe7022c823939faea138cffa576671c5c2f30bb9baad7d0cf66
1489           LICENSE               1e933ceb3f4a00ae33672d4e344f9ff26e92bc8f34bc0c7a52fd0ef257607858
395            Makefile              02abf7a21a3e70691d33338da881c966359adaa1a138c57d1c5815ec183acde6
67             README.md             f278a0ddb855b655bc037f249a7009a7f6f2b459b1a1ff173ed128ed53e1331d
               lib/                                                                                  
15722            cmd.js              59ce39027d5e22269ac8d36ad8637020019f2d9e2529efb85b007a2bd48065c4
301              main.js             77ab4401be53df151e975af754ac776d513b8f867bd8cb369015d9942f95493c
4029             stream.js           00a5e161096744c922b0f5ea030bf74d375d2b7159405b181d95b6276d6ec521
752            package.json          d66436b631a2b8b217144f4efe3922d6b5d6d3a7db77da601e664c99ac497ed9
               src/                                                                                  
6569             cmd.iced            2825f8999ab597308752e33a7a78c412fd4ebc508347e9c007e356a31fcd227d
105              main.iced           ebfcac1e8601511a4413583b4dca40bb5162ee02ef2295b418911991efa06fc0
1898             stream.iced         db23e88641eeb10efae2e67339c3330609298592b47c6eb65b8780ceddbe7af6
               test/                                                                                 
                 files/                                                                              
3324               0_basics.iced     4f9e2e14e23ec96120cc4d892e0c68cb0b3f500a5ca80d3494791795a6e534ca
797                1_other_fds.iced  7a72b8a0cbdf73365b3416c20c3f0759637f76589f0d6709b362efa614915560
353    x           write_to_fd_n.js  91fd6ef8d8f6d26c183e92b6cda00319cc3f9471158f8bc266d398f0998d3bc0
184              run.iced            22ba5b18735c1555661cae1c7e91f76b2a4cd350863957ec5137a133f177ccfd
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