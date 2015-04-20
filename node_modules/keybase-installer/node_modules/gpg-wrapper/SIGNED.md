##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJUahLUAAoJEJgKPw0B/gTfPtwIAJBCXUgXEr3YJkZa0PLdA367
T65sUet6dtL2lccEIZpJZrI01ih9/xsKOdFWDlIgRrOzf1ETUaMdZImZnuBpvUO8
Q/x/NbXFG3rDfoy77P5xVeW+mmpAx+xnR3fICIW8iXM5sE97pEFb+uJUPTphqlUU
X78pP5A3z8i+JaPB6dZI5XQrkMlB71VkXmiwIEB/7xlqfz8YmvzXEVSuILfnEjLZ
bPWtJUBNoLUw02qaqUhitaYehvOAlZFunTrA+yOXLCFfu1YQP4s35chXVk5lwO2H
N9PkXjumXeIRewS6uAFms6BJ/H8goPx8bloDup3ITeMcV5RY+HOzHXvEh4kS/NM=
=9fuH
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                contents                                                        
             ./                                                                                  
109            .gitignore        ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
3606           CHANGELOG.md      7005816f08a0721caff716ede9db01e4dd8b8a093aa5678f66dc735fb746e91a
1483           LICENSE           333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
502            Makefile          960fe8002c2c2866c0963c9b0ed138dcb2a4feed693a3c668875935902f9b486
55             README.md         fac7947ca164bd97f854cec88bc0266773ec378f4fb79cb1554662a4fd4079f9
               lib/                                                                              
1100             colgrep.js      8cca2968a077b03d45b761139276f24f32b2a6948ada5fe825fcfd804105cda2
408              err.js          ac74e7dbc52d8da10a4544bbedb78619a5407cdcdbb3893e7584fc5ca41c8e0d
9864             gpg.js          58f656e45b780600861b7d65c55a3720804ca9697f8cf996247486829f186bf5
11120            index.js        821e84c563ead9729196d12a80f3d990cd485fbe16df6de264fdc457fd781286
92762            keyring.js      fda9c5c6d615c44e6ade52b884bf672c970a4737c9a2edee3f693c77df39e61e
387              main.js         92476f33f1ce68c8f74c993c3b3d9603b9f435f44a69ec3098e552b0c4d736b8
3985             parse.js        57abc69755fc4eea76600b17082827fc23574fd7ba5b2a414cba40b89f0150a2
708            package.json      90fbf4bba998fa06495eed425c5d7e091615438c7fbe8114545eb71955f038c2
               src/                                                                              
604              colgrep.iced    a3c53c57e739b9af47f7b8cdb31c3aaf3f7416c978e7905ec42bee4966bc3920
351              err.iced        db7ddbbfbe1f076ad895a83e22cac8e720f260768456dd6aa0c97e5faf7ae9e5
2590             gpg.iced        cc3921f2f7c8b56940b3a8170e587d9375e7c58c50e873134c79c969c2db5148
5740             index.iced      8d9d3029f836f5c608a75d010e557cc7cc7da8444b530191c9ca4282952dd8b2
28456            keyring.iced    091e445fbb29355b5935e19c35f5952ec315bc7029550b7a122c2e76d9038192
225              main.iced       d06200c91a7f18bf1ece9ed92123ecf2362cf4592318ca23639b08356ce877ab
1731             parse.iced      f031af161d3e124ef77ed4ff2e679b84db797c2462d407be0975383c30400857
               test/                                                                             
                 files/                                                                          
1066               colgrep.iced  e055590058160122daaddaf0fe2784394981c3d599a86cfce892b31dc89e030f
360                error.iced    d47058171d6c5a61c57829d9b9fa05f6c06153ce899d6a6ae61dc13c32b956ac
1690               gpg.iced      d44f312444b293b551240e3028ea08b3e7d98818c9df58f052ec37b78b410b1a
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