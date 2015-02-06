##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Comment: GPGTools - https://gpgtools.org

iQIcBAABCgAGBQJU1B5wAAoJEGBSsq0xpmMcRTwQAIovRdTMAil5MmSnpEV0LRJn
1Ukt41r86L20LNRWNoqwB2LdmH3M7c4GFGU4KZ0qpltakBF/1IIGwKqItBO0fyDP
o4Mk8rnDSkRBGiQWq9Qgjr7TMWUvTmOKnHUBHn5lZjmD/AERLWYPpQjuAuATfuhR
WyFcWokoUg86bynb/0v0K/pmiFt1rssGQmjJkt2EDjO8OWTJ1BT0icLSVoPCsD5P
sAk8gSmPuplko44MYQdKEqTt9vEDBJ9COL9K+qFz36Ap4EW35aryC9kxz4k/vXoK
XZ3nFrgiPCsxXaUqZixRLOcUIvagGSZguFDO+kduBhShjaySBRigbhi5oCjuCZX9
Zfmagtc0tTPHUhTL6PspAPFol7RsY0Ys3hgXuhclIOtVPkSeKVaBsq8N1Cn4Rg+p
gWvAlvmav4VOW6EPrrEF5SuMHZRls0srEQzeBSZtuNKlrRj4HC9+tp+pt1oUa5G3
uRknr2DxO0e40CzYAwVeuLb4XHc+9ds5E+RTs7DcLDATxIBZZMz4L849ROwIedYq
2V1BDD2rqe5r7lr9lclwR9Qkz9UmixR7KYLM6mskWzCBPRb8dTuO8dJKmTMapfDi
YwSFwKai2mgHrJj6SOCh+QH5x0+4PMIAk+8sPa0pV3nT7yQ55kSlpWq+iTVCpRKW
r7BZlQ6WLP7iniSj4Fwd
=YKzI
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file            contents                                                        
             ./                                                                              
599            .gitignore    1e8375541a3bd48e28c8940d632fbc0af491732ad749995a4557fe2d40b0f613
43             CHANGELOG.md  de747ac9b582561d5553651ba67d48f2840440dd7c27a55c41a6e659c28c8f03
1481           LICENSE       db52cd1fe0ee40a28545894bcf171df7b88cda87e207872674f273f04363b3a9
352            Makefile      77be5bd1a882e0492de13b45ed94ec8e1b8259f82753a04ab9e6b5f0501202ee
701            README.md     7abe0237766ac2a1204fa2b1920ac9b5c92673984c0a42caf0609aa57bc6a730
               lib/                                                                          
11462            index.js    82daa7c5ad02ab0a58d38cee770dc2245a0f1776810274c5a30faafad14bceb9
694            package.json  589728c42fd02880927cafe176e49ef9e326d69041e1c873efc729ed9f671abf
               src/                                                                          
1902             index.iced  6219137367b07bf7eaa8d1825e7161aa37b720e8bb6c0c0a13f800027a382b7a
               test/                                                                         
149    x         run.sh      c6674084532b3eb5f2c36ec668b7e9e8bd15b062ef5472461384887bea4ec2f5
193    x         test.js     61af6b83613878bcfda8b3c999a7742628df7c0b3cb403acd5e5c989b5287f03
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