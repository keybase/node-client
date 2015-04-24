##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJVLm5/AAoJEJgKPw0B/gTfXCgIAI7pfkBBAVDyjXJtT1Puzs9M
znnu1c0IrPkxJpfDufRLCXuUjstzBqFLwtbpbENyFmrAyPOZ7XdRCsqG9tg9bWOC
cmO0+Jqqu8hVe7svcDZovBd1Tu0ZDBLGuwyUjDxjKh8vN6iYPnH/Irb+U+fmrVBN
DbYZL9hn37cClr0jIRI4RwgdnWPYR/3cwFii2r8/OFIkVhtv0gwiKw1MfbPV5p6k
XzVGedduOfunnfW2EiitWdX2IYquD/5iIrgnWn74Elm0kSA+rcsiSCf5Atuv7HmV
32hyLrUkzhuaieXzGbLdVCVKDQ97oy/rWX/8OH83AHPgbQqYL+OKNViBdW+iuxE=
=xdNj
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                contents                                                        
             ./                                                                                  
109            .gitignore        ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
3894           CHANGELOG.md      1d0224dc57b8a929a93ae89d11db200ce488b0f6350ba03dc941b8b7e967b472
1483           LICENSE           333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
502            Makefile          960fe8002c2c2866c0963c9b0ed138dcb2a4feed693a3c668875935902f9b486
55             README.md         fac7947ca164bd97f854cec88bc0266773ec378f4fb79cb1554662a4fd4079f9
               lib/                                                                              
1100             colgrep.js      8cca2968a077b03d45b761139276f24f32b2a6948ada5fe825fcfd804105cda2
408              err.js          ac74e7dbc52d8da10a4544bbedb78619a5407cdcdbb3893e7584fc5ca41c8e0d
11059            gpg.js          3e71dfc434d1daee56dd8f0f7e9d93651206327aff65e826190d310eebd28fc5
11120            index.js        821e84c563ead9729196d12a80f3d990cd485fbe16df6de264fdc457fd781286
93077            keyring.js      4c07bae03a1a126f2af039d89a3f7ca953d48c5f9d51fdc0ac536fd317b1e154
387              main.js         92476f33f1ce68c8f74c993c3b3d9603b9f435f44a69ec3098e552b0c4d736b8
3985             parse.js        57abc69755fc4eea76600b17082827fc23574fd7ba5b2a414cba40b89f0150a2
732            package.json      f81598633c7802a7dd7016f952bf11c88450d1d6cf19c4caeac04a0f075e6f7d
               src/                                                                              
604              colgrep.iced    a3c53c57e739b9af47f7b8cdb31c3aaf3f7416c978e7905ec42bee4966bc3920
351              err.iced        db7ddbbfbe1f076ad895a83e22cac8e720f260768456dd6aa0c97e5faf7ae9e5
2942             gpg.iced        41ced8c0c6e399a62d90f8a464c58e463d9fbf4d99a5383dd67d17529d4bc70e
5740             index.iced      8d9d3029f836f5c608a75d010e557cc7cc7da8444b530191c9ca4282952dd8b2
28647            keyring.iced    3e4d9d639ac6a205cf69ef0d67ab64a54c202bee22ba6a3cda3de0e99fbe6bea
225              main.iced       d06200c91a7f18bf1ece9ed92123ecf2362cf4592318ca23639b08356ce877ab
1731             parse.iced      f031af161d3e124ef77ed4ff2e679b84db797c2462d407be0975383c30400857
               test/                                                                             
                 files/                                                                          
1066               colgrep.iced  e055590058160122daaddaf0fe2784394981c3d599a86cfce892b31dc89e030f
360                error.iced    d47058171d6c5a61c57829d9b9fa05f6c06153ce899d6a6ae61dc13c32b956ac
1800               gpg.iced      d460e8db71481e1b99ace3e3c6d614a3c4a7b71dea3dd5a7aa08033bbc1c6496
10403              index.iced    fb73ed7d38df999852f8b68e0fcf2c37615f24eaca8d83e2f9b353d18380f338
36230              keyring.iced  1198771e057f5ed60cb03847334e173c67ef5e5982878586138bf1054adab571
1458               parse.iced    6502b4cbe550249868f8c9f257b621898ba76acf1e20242ecad1b811e0829c3d
183              run.iced        822568debeae702ca4d1f3026896d78b2d426e960d77cb3c374da059ef09f9fd
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