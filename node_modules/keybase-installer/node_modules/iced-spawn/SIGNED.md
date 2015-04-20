##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUIW+qAAoJEJgKPw0B/gTfl40H/RBBKI+kjCNhSFO3f1bAUBIT
hE6+cEMFAFv9S0GTh32b6ADltAY6WRkpVk+5hYvY+/twjqDwL0X033TowfTvr6hK
rbFVozdT4Gx6memRCWPztUsOKAlA04JzwgU9Ru81JuJYANfcO50wOx65JEP+nVQ/
U6Br9rDdmdPjH1grxl5euOrXylPARXcVSQQrX/aOC6voRXh+jS+SBe4vduLsWGmi
BMzebGMWjvb0Yy/o1mIMLWalqxjJ01iuHt/FuQYttQEWsmTPzTWX3sPpgg+CdHbt
HNSy0g78DF31io19I/cqql0aADQfwOuoIO6AmAVRftyeoXFi/3EZ7wdxCf9Jqaw=
=lE57
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                    contents                                                        
             ./                                                                                      
109            .gitignore            ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
1262           CHANGELOG.md          d166bcf97a18d42a9fb07390a9cb2d7062214d965c129b057a424d18556c8830
1489           LICENSE               1e933ceb3f4a00ae33672d4e344f9ff26e92bc8f34bc0c7a52fd0ef257607858
395            Makefile              02abf7a21a3e70691d33338da881c966359adaa1a138c57d1c5815ec183acde6
67             README.md             f278a0ddb855b655bc037f249a7009a7f6f2b459b1a1ff173ed128ed53e1331d
               lib/                                                                                  
15596            cmd.js              ae070a5dfa716069b0f265d49047281a3cb796f54e525f5e47a5e4df66f8ce84
301              main.js             6d422ce96c4ed5d06fa50eed665c65ecc9b8113831e0a7dc131230e57acb724f
4029             stream.js           5de24fd5e78e0da6135a858967054ba6076bc7b6780f1f12e5fe0005c1b69e03
757            package.json          f4ca28079daaf5a4c271c73729b6489a69e1b8ab04c81e7db62635baded66222
               src/                                                                                  
6627             cmd.iced            2ab7a08cb365927f06fa2a5e61d3cc309ef9abf2017b8b8d6ef50ce95d6a1ce0
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