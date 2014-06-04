##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1

iQEcBAABAgAGBQJTj6PQAAoJEJgKPw0B/gTfig8IAK1dMm9nYsauEM3/3e85CbT7
/rV0MeESlU4y5aIx5rOm/xRHhlTKLGa9bkTVqBzbYe1YFYmaL0h5U7ZAOs4FE0aW
dBV2mnFxSXui+y0ELnNr5YpfPkki/d2dKgqd7/RdoIhOuqeVnHt0XPEBi+zbKeIr
wQ+J7W2waKC3N0Aab5lgZl8AuCbKl5Dk95Cp4zsHtaHITic+4quurxJzUsMjHGoj
hBWw5rGkT5jAwCUt47GcX59Ep/ZMUP2mP9MVFdGlQOQ6UkOC+wnlO22Lhywy7ib/
8Zrm1O5iszXK4qC+r1x/fdFpmGlG2RilTjKJYIPN2uAUUXIGb6Me79rqcTkrfyg=
=SFRe
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file               contents                                                        
             ./                                                                                 
109            .gitignore       ec278daeb8f83cac2579d262b92ee6d7d872c4d1544e881ba515d8bcc05361ab
992            CHANGELOG.md     992c20d424dd8017c32b78cff82f808c553fc32c16a7a5a0f8770a218e45e964
1483           LICENSE          333be7050513d91d9e77ca9acb4a91261721f0050209636076ed58676bfc643d
437            Makefile         a031266cdf17cdf3236a0f641bf9eb2a882bf49b5e5aaac8686e4d02e5f0c4b5
106            README.md        0d5a7f840664005562cff3e2cee8d0d2e7468e24c4380169b6516ce318602f50
               lib/                                                                             
15276            armor.js       bc0ebabff9d5c93db3538cf7a4e43125b850cd64adc87b7475454af720dce91d
187              main.js        c94977c724c76d803edbf6a08ddbc300a6aa930bf777fbd423eecca05f19fc54
814              userid.js      2d0fff34cdbfbe9ccc7c80cca2a5dac70328e813178a41777efa4b3b1bf63650
11298            util.js        e78832db6cf9743624c1105b3545c778e39b83c30448578e414a543f443994a1
740            package.json     d0ca13d9828242d1170df4b27ebcd373e6d15eba6ae164107daabff8161cdaf6
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