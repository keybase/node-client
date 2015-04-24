##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJU5LuzAAoJEJgKPw0B/gTfOokH/1d+zVfHAmK1eRzcdOGn/zZi
utIbKEauAz8SRPiRhRg4hAKqbnQ1uM1MYpTwYLj6Idgh5BSgTmcdbZonBAFZu/8i
ZpNDOh5N6tUzmaQffnLjsRcbCoJGQfQ85u5QBA8jI9CuHRc9cJh3w66RfMvqfsQg
3eLztfOjucIkmymh6Vqv4yHUiRoWWj+rjdDiwHMxnm4Wv+kGKxOxsG6IuzVa6OaN
KDikzjrFEnoY7u3sDwSkFzmCt4jXKLD5OeS7fv0jggNymQlTEYpoCyVIG8FCKsZw
dZ47gP12wm4CviNkMkm37S4cJOaDz7OIRJM6J6z4A/U7QTE6i9xEMr5oLpu/00g=
=13vH
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file               contents                                                        
             ./                                                                                 
109            .gitignore       ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
1593           CHANGELOG.md     ca67dfa7946608a3f981c998b419a66f00eec539a8b747a498ca8228c6a3defa
1483           LICENSE          333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
437            Makefile         a031266cdf17cdf3236a0f641bf9eb2a882bf49b5e5aaac8686e4d02e5f0c4b5
106            README.md        0d5a7f840664005562cff3e2cee8d0d2e7468e24c4380169b6516ce318602f50
               lib/                                                                             
15571            armor.js       632737aa37a0539de2cfc35c2715955c88e557ec823b9ad1dca34b25aecba344
187              main.js        c94977c724c76d803edbf6a08ddbc300a6aa930bf777fbd423eecca05f19fc54
814              userid.js      2d0fff34cdbfbe9ccc7c80cca2a5dac70328e813178a41777efa4b3b1bf63650
14013            util.js        228a72ce37f39b634c2ebc62f0f656b4321cfc4b91ad2d192dc6f362ae223192
740            package.json     c1d5510a609791e8ce157ba18fb137ef7c9356e9884ada11e69bda156d61d710
               src/                                                                             
12835            armor.iced     4fb76a5afbe8030e3ca44f1e3a90a03165350d9ba508da3510692481103d3d69
103              main.iced      4f6935672c854424a9d7dc96d3e446d39528b76091b4d06e199c67c5511cd09e
843              userid.iced    d73e0350adfdd2a397fe6971109122db2d2017e05aa4911b64fd729144c322ae
8186             util.iced      070b483eea376ea113eb4970ee738eb267613dd2101deeb2c2af178510053b2a
               test/                                                                            
                 files/                                                                         
284                fp.iced      bc3d84c1b81f709694635247673f71bb3b1898b5a8ecc09a7d977261e09042e6
1627               t1.iced      025f26ab9a72bc0c03ff9f39071f51d5fe08023cb5f38717082b587eea9bf5b9
4014               t2.iced      646fcca1ca1648260a94b9f6cb0ffe8baa734b928a58bb94896f1787bf685f52
2163               userid.iced  877fa6a2a5113ddc93a45408abc25ba2a206501c873279786fa7f7bd7e8c7c30
169              run.iced       70ef38fc04a9ee264e2317e5b4dcb00a69a996139e98b5d9e34d0ffa16609479
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