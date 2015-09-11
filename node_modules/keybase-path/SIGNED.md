##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJVLmuMAAoJEJgKPw0B/gTfEXUH/AyvthMSEVCgO8vzoyZP4Avm
p+X6ebabxmkxhdsB9bg1I47SeBLtMWMI2xpUB9InWFITwU1GnMw1YzobZS1lQcKH
hodl/kjrs3XivgNim/zjLCVps80S33MFmgYld5kSt/OOVMF5W95GWKD3RnRIRU3x
3wujr7YR9l7yAvEuotLZvOD/8AV9rk0YWtPeU8fbp9Z9M+nNfd2HmcefJdEdl6u/
HbcoOkNZ7oB/cGbbwAKRrpfYymrDx1NbDzBkZ/f2DeNFbufrnSq0JHZDa8Iakxnk
k6352sk+YollhJ6n0kdvsGVv53vyWqUFfAcIyOvqxw2J/FcjflVudMgCuwYj+9Q=
=sDs/
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
6913            main.js     5f596e364b6ef4c22a13ae8cd4e25e4a0701cfd9755ba1abccabb559249053d9
681           package.json  1481773981081959048bb8999d2f58eb31cc75e88b91a6f2f148043ffe0ceb12
              src/                                                                          
3559            main.iced   41a5ebb6abf4c0413da1c0b4a4ff8c30e6e9a92f5c0647b72432413c7cf31c12
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