##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2

iQEcBAABAgAGBQJTybT5AAoJEJgKPw0B/gTfWngIAJ6drLOYdoRwBcWHDffww0i7
457YrD67xojdcV2a8kUWK+xHRZTI1FDctKdcwwAzVRstEYZ5xdJtdOkQ+9RO5L8T
DAcx8nkc4NT8MYpnNnFmQEGqxF6N5Fw9IU2qN31iP69cWOdHtOhCJ0YXfQO2LGAQ
yQMEQuGwC56iQKhkkcpijbNj+Cseiqple0oEZHLH9zIQSsBDMEPyuB2r+bClTDLk
xPZ/59W0ncmgQ+28OLB5k4htnn+6MZPIY+ZWs/slSnnKlCI/NFJFG7uORRaHv8Jq
Y8jzW/nS3JuLIHjH4xG/U2DhwCY7vKkg93W24sZtydxsc6tWCz0ovPQnm0GWilU=
=Gk/G
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file               contents                                                        
             ./                                                                                 
109            .gitignore       ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
1487           CHANGELOG.md     cc232ad3765b99333d9cdba90bb54f0de00e2f87845dfc6c809cbdd94866b92a
1483           LICENSE          333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
437            Makefile         a031266cdf17cdf3236a0f641bf9eb2a882bf49b5e5aaac8686e4d02e5f0c4b5
106            README.md        0d5a7f840664005562cff3e2cee8d0d2e7468e24c4380169b6516ce318602f50
               lib/                                                                             
15455            armor.js       b1dc8663860bcb9c228d7e29ef6ebc7a18781094178fd6d4fd87d450a18c0a09
187              main.js        c94977c724c76d803edbf6a08ddbc300a6aa930bf777fbd423eecca05f19fc54
814              userid.js      2d0fff34cdbfbe9ccc7c80cca2a5dac70328e813178a41777efa4b3b1bf63650
12760            util.js        b6dd08e6eb21c7bc844cf861ad4b2719a9a9c2a48f8b11a64b560ea83c8d6b16
740            package.json     94b77f1cc55160ecdf89f6c6ce0d84fc81bb9cdfb61fcd0e710940b8862d9940
               src/                                                                             
12767            armor.iced     1b6139fa13e3d3fd3e1a373c0724c0f680a362c081b0410f8ba956575176c4fb
103              main.iced      4f6935672c854424a9d7dc96d3e446d39528b76091b4d06e199c67c5511cd09e
843              userid.iced    d73e0350adfdd2a397fe6971109122db2d2017e05aa4911b64fd729144c322ae
7630             util.iced      b2267ec8b70da4d3309d2eaef2b2d45a8b0b291739b9150a3331fd019b52011d
               test/                                                                            
                 files/                                                                         
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