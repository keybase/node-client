##### Signed by https://keybase.io/max
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2

iQEcBAABAgAGBQJT2NgNAAoJEJgKPw0B/gTfVcsH+wdCi96U7ZEuL71BQ3FoBRPB
mvN39q34wIlgRhm8d9pp6yRktHdt3tNjGtlnoR2j6b7a9iPjIkFSQwGhoQMwrB0H
zETZgPuCaHY/RHeMUBvufMydnO/WchvX0fKqsn343nGU3FV1QDyRqSdKWKmZx9I0
yh/E9+pQfhiCpSJsY3W6YRjW6tWEqaR1r0TipEtNrO4jfhliL5y8DeumEJFx5Ey9
+YJOTg1cjgq2V3940tBSuflgJWQCw/1QYYfzmFfmn98hCMijrQeb4D6dSyNMhcBI
ci2Ibxli2rIXGonR++GJFlWP6twAPkQ+moYoGr8vQlusulTjS9mH3n1XL9iptbs=
=RxXF
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size   exec  file                 contents                                                        
             ./                                                                                   
33             .gitignore         044a875c16eed65b7485565a6eef29167ffab92b5ee4247a5e9f3b8203faf405
103            .min-wd            5b779cd77bc3f45bce80c1f7d4aeea4b11ff874e6eafebd2ebac6657c378e219
72             .npmignore         013421fd6eee4c2812a4342b3c944349b1f64ee94f3eeaa152825003731a4181
172            .travis.yml        51a676eeaf009d3eea6773b6efc828f4807185cd950895a85b865fdf51758c45
5302           CHANGELOG.md       657cf5f94b23c928320c52c7fa8833d93e86edcf7b23786450583846eaf13b8b
159            Makefile           26c6343df0ac899866055d5ebf76251b81bf93581a81a31cb9a0dc2ae6c9ba59
599            README.md          bb8247bf8afff378db42dea36408955b4c7b9b07407689ecc212be21f3363d01
309            jshint.json        f61b0cc0a09a7b7adefe7a1cc8d30f7799aeeea8bedddf3ab3b265b8e680baf5
               lib/                                                                               
1840             curve.js         e4399114d747a0aacc4ac4ec9b79d2a08c1761b1f590b18eed50fbb7d463e39e
2543             curves.json      d46c62c9a52e0a0f258522935de19272f2b79be804a6c13d4852a267970682f1
190              index.js         c5bd5761f0fdbd7a11d0755e33bc36cd15ed78b3089f9c92ac3d929ec2828cba
542              names.js         7f7d401cf0b22ffaf934aa6be8e36799bb631c771545b57e4069faf79df30c08
6414             point.js         a06693e6bd50c8673166302e4b2a18047f334a5a29a086e531cd894a53d10508
1242           package.json       939d7a181399763a605fd8f2fdbe88e5aab0f014f52a321dd8a821dc97917f5c
276            patch.sh           378e7b47c88c843a39ad22d0017f7bb98f783d5891553f1054cd6cab6ba4fc1f
               test/                                                                              
10371            curve.js         ed82b768513b532187b630aeeb9028f3a984b879e034aef8caaef521fbdd2cb4
                 fixtures/                                                                        
932                curve.json     82dcb87156c194f85072d1a54a3201c792f93d3f47b9ef1e48890d98b37727a3
93532              nist.json      b09a197421b6ee144530a5e4e0cd30cd6caa44cecf7504b88c2dea569ba1af05
3951               point.json     1dd500fd162becb8c0391acc0a56177becdfa2d1117f2ce7bfacc26a1d7a48ca
39               mocha.opts       74ff3e60361757523c9cacc452540490fb2deec1bace92f82b12c06702a4e1ba
1026             names.js         8d9f576495831570148feb1428fcbfd7d678597f903fe052842973149d282e2b
852              nist.vectors.js  dde7e20c03a97c59462ce52edae544cc23ff1f0f6b8a70a70f0078118dac5b74
3044             point.js         3b4793d5f393a98918611aea4692193362973610c7f7e07b390492b0454289f3
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