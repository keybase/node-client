##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJTjy8IAAoJEJgKPw0B/gTfkbcH/0nvkjHRvsObL0/3Wb7spwGW
KArToHoLg0XBKaLaIDFMtbrgtj7nBC1V26udU6pTiPaATUZrVPAHz7MklgztqVVM
Ec02/buXnY0WsKo/v6H2spDDFy9M2gzpdRrymzZ67ciMOuH7g2YqYHXiLUzU/Ro2
qn5vSbByX5vXxRxk6JWrK5O+NWLPscQIuUuuXshZa7qpsVHqeF5SudRsO8q5qgXh
9e5seYCoCFXrwPHwZu65H4asnZJPNsezX67bBe+QRJrQz2H3qm/tEXx/gOxXCrG2
4JsedXs4upt7G+idSxDLjy5oZWUHjbL36zFNVu9E1hX8qKSrwKB1J1h5h98NFQg=
=2kkp
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file               contents                                                        
             ./                                                                                 
109            .gitignore       ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
919            CHANGELOG.md     39b33135407f2c7ec691391223c94a0598fea264f0e33959dcd6734d582760c8
1483           LICENSE          333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
437            Makefile         a031266cdf17cdf3236a0f641bf9eb2a882bf49b5e5aaac8686e4d02e5f0c4b5
106            README.md        0d5a7f840664005562cff3e2cee8d0d2e7468e24c4380169b6516ce318602f50
               lib/                                                                             
15276            armor.js       b572d51515334ce8a9c57c4874cbc9592d73d34aa6468fd06bf34add74281cd2
187              main.js        3af89a1a7aad4a34d84b4d6e7e0785aa138bb279e0c77abec5eb2a6b3b48aff0
814              userid.js      73f17277c738d689a50e3fb573f79bee5de1f954a2c9175039fdd28863ff12ae
11337            util.js        58da4731c6bcd9245999ac671bd12e0d5dfb5dfb428ecf3cbf39e361ed3b4ec5
736            package.json     cfc5d1482fd2280b57f1cc4a0f27ef469b554f815197e6ae07a95ffb6844c299
               src/                                                                             
12585            armor.iced     4f2bcfa15ca0ad895daefaca0d5856845fa984a9c362010423796f15c89eeeaa
103              main.iced      4f6935672c854424a9d7dc96d3e446d39528b76091b4d06e199c67c5511cd09e
843              userid.iced    d73e0350adfdd2a397fe6971109122db2d2017e05aa4911b64fd729144c322ae
7022             util.iced      c58b5a8dd6d836b3488e2aef5913583026abf5b9afd1683a3bef3e79c8d19f46
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