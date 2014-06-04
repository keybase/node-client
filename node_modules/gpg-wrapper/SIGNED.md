##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTjz9FAAoJEJgKPw0B/gTfYNYIAIzEKXwnFT709YfHZgPbsS/Q
C+oKBmcAHIyyUoe8OHkhHY47iRAzg+/eKRuW/Ph2g9NWE3GFUVMVjqADxobqJA5T
QmIvNHr86S8ZrrsM3+hLmpb0MofKWgjJGZXrCD6ol/I3T4XadcpIwkj3KcUn4pw+
7HxNsTdfyX55kYagq+nbgbHW68bMP4nTxcT6j2qo8iEuir/bBd8rWEF/cXqrhYiw
pfzA7n7KQBTSCTHNQ7vCifqs2rF2J3cWHwzGXtXqzFuARK+hr8/ugAocfnU5H++x
gTlkggN8VE9hrjvEGg/c+NTTh9ro7X8rwRyGt5R4Bk3xr6ejKXRe1AJt+xPojIY=
=CgZ8
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                contents                                                        
             ./                                                                                  
109            .gitignore        ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
3286           CHANGELOG.md      b89fe962ae695692d3db19abb44011fec2d1cf9fd2f8ea69d72bc0aaadfa14ff
1483           LICENSE           333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
502            Makefile          960fe8002c2c2866c0963c9b0ed138dcb2a4feed693a3c668875935902f9b486
55             README.md         fac7947ca164bd97f854cec88bc0266773ec378f4fb79cb1554662a4fd4079f9
               lib/                                                                              
1100             colgrep.js      8cca2968a077b03d45b761139276f24f32b2a6948ada5fe825fcfd804105cda2
408              err.js          ac74e7dbc52d8da10a4544bbedb78619a5407cdcdbb3893e7584fc5ca41c8e0d
6260             gpg.js          68aca49cb3023b84fa7c7b3436b6856d1b160b201828f919afebfc7a79ae22cf
10991            index.js        0db004e6d3b606d0b5b385a9b91cbe6a8dfb20a793de8086e3084dae4d82ccf9
92793            keyring.js      efefb8fa25ced79524992309bf82282df42fc4d5c44e6b972700bd69d60ed5df
387              main.js         92476f33f1ce68c8f74c993c3b3d9603b9f435f44a69ec3098e552b0c4d736b8
3985             parse.js        57abc69755fc4eea76600b17082827fc23574fd7ba5b2a414cba40b89f0150a2
709            package.json      34e99830ec6b14ba78d22f62754b503de393a3ff7eb32d098bf7400079018181
               src/                                                                              
604              colgrep.iced    a3c53c57e739b9af47f7b8cdb31c3aaf3f7416c978e7905ec42bee4966bc3920
351              err.iced        db7ddbbfbe1f076ad895a83e22cac8e720f260768456dd6aa0c97e5faf7ae9e5
2061             gpg.iced        711eb4cd6636075cf6cdfa327100c47c69b286eefd61859656e1c6ca7aeb56fb
5674             index.iced      a0e6e71b262131c546976fc6adb140016c26380505cb2305dbcef01e4a3fbfa5
28498            keyring.iced    49374a8caaf86211795cb98f844d0ea29774da7be4e772e1e96eee9901a64bb3
225              main.iced       d06200c91a7f18bf1ece9ed92123ecf2362cf4592318ca23639b08356ce877ab
1731             parse.iced      f031af161d3e124ef77ed4ff2e679b84db797c2462d407be0975383c30400857
               test/                                                                             
                 files/                                                                          
1066               colgrep.iced  e055590058160122daaddaf0fe2784394981c3d599a86cfce892b31dc89e030f
360                error.iced    d47058171d6c5a61c57829d9b9fa05f6c06153ce899d6a6ae61dc13c32b956ac
1095               gpg.iced      fa2898ab0e413f32ec63da7e067bae699a4247d9399a8e02bc27d52d715b94c1
10403              index.iced    fb73ed7d38df999852f8b68e0fcf2c37615f24eaca8d83e2f9b353d18380f338
36214              keyring.iced  f91c6534f85e4a1c09144539d03026b9152e86e45b994312b6662233751868ca
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