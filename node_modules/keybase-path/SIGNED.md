##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUGKioAAoJEJgKPw0B/gTf3m4H/2qpgm9/SKRNDs49VGInMdMF
+xdTItbIV2DbCyEs7WzR8bIzRiYLwZUZypqiRicEBuMfM2BgRI03NPPIIi0Juk+e
EPs58UMBkbZUh+1k9RXMAylyl/599oWqHhAvCZHj5qt2Jhop27BdT1NYgA/Bv0ym
y4L9WR3OeCYIMBDcJ+oHK1Ce06RlxeUgSWm2CzpaqCpo6slz+9Fzk5bm8Cv26Iqf
dfX5XXW5dGQAK4d4sdh0dRhzLjuEGd7GSjSRmBUHvzH5pnAZbaZG3fXJcBamzpBN
XBdvVJEertMykXAX9IUtFUFNgdOMu7a3NLzG78eGMRPTgKu6xilSc/6PJFefbGg=
=ja5Q
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
6891            main.js     b46b3306b91345fe1925b502e2c572244d68c61e51b156709b58e279f539cadb
681           package.json  8ea1ecc0b3a3f01a82eca097fd8eaca8a948a6adcf10cd9f0023e10d6b4fc675
              src/                                                                          
3538            main.iced   bb9510b75a3c9462b8a07f091308cab8b42a93d7667cbb4e4dd41f6776a5db81
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