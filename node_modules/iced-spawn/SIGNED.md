##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1

iQEcBAABAgAGBQJTj6ZVAAoJEJgKPw0B/gTfKf8H/A3/g74JeYUct7d1Nb9bbwQn
mJSyZw0bpJaZaumTu1RYOGSVroYLWwa1qUjTsU1WEuKN48wOt4ZQg6vWHT2aLigE
myh9XUyPtapvr8cmMRNtn/nDELXbkaEJ9kPuKBfCQ/aXZsYukthirAbbIFXDsf+l
lqTxXlqcU1XSJfT8k7/JX7tl6eMakx5kB6NS/Z/32ehnB9V4AAhybIGxbwwa/VVm
pQWpJ6d7HbjOfL2ut6skniOzy1Uzuqu5UqeF8go/qRwn+T/AckPwazJ1PJVAnkSK
HG9/hM9pv2USnM4tU2C7dYJZrORsDwMVBeDN0sivlOh+PzjfODg0CZCp6uuBaYo=
=6AKL
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                    contents                                                        
             ./                                                                                      
109            .gitignore            ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
1092           CHANGELOG.md          e03dc2c6345d8e3da75859f07d768369eb2275a272d6fd68d21395a91b4a16cf
1489           LICENSE               1e933ceb3f4a00ae33672d4e344f9ff26e92bc8f34bc0c7a52fd0ef257607858
395            Makefile              02abf7a21a3e70691d33338da881c966359adaa1a138c57d1c5815ec183acde6
67             README.md             f278a0ddb855b655bc037f249a7009a7f6f2b459b1a1ff173ed128ed53e1331d
               lib/                                                                                  
15679            cmd.js              5e7c7fe90451eef075ea7ce9b08d67fb4fa95f04a711af9d80daafe663752fa8
301              main.js             6d422ce96c4ed5d06fa50eed665c65ecc9b8113831e0a7dc131230e57acb724f
4029             stream.js           5de24fd5e78e0da6135a858967054ba6076bc7b6780f1f12e5fe0005c1b69e03
756            package.json          c8af9665f20ef23a4bd28f56b34ba56923b507f63673ffdfff555525c54f1fd7
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