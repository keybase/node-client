#### Verify

```
size    exec  file                    contents                                                        
              ./                                                                                      
224614          node_root_certs.json  83de1ef6b6c776c4e9dc81af4666d77b83938e3364b9940f80a82645fab87257
```

#### Presets

```
git      # ignore anything as described by .gitignore files     
dropbox  # ignore .dropbox-cache and other Dropbox-related files
kb       # ignore anything as described by .kbignore files      
```

#### Ignore

```

```

<!-- summarize version = 0.0.4 -->

<!-- BEGIN SIGNATURES -->
#### Signed by https://keybase.io/chris
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQIcBAABCgAGBQJTcjJWAAoJENIkQTsc+mSQ7NoP/2sQSEd0GAIOE+cLNJadbW+O
kSQOLnhpvJ0lPgdJSY6oK+PgblUP2+TNzOBrSeoO16HdFUKXz7IG/LcInWh1ZXj6
S42mGQC1dHhzuM/ydsVpym1MTYA2UhFfvr8rabKhpBsOVW8letxhPMbkJt+UcQIZ
GUPQohweAMgMOvw4Cbnhm0X3I9Hg/oaPaXq1UperDOLSWS22uF5oQKNEwnWlPrQk
dpX/myVggy3g0hbx4Mgc+xIBXTtlF0mkmW7W4qHbsT6QNdXNSVtXTsmCf81cRdbE
D2oyw7xXMGbGxmScba92W0benZNoLvqtGcXqdG7Bj4cM+d7isnKQAkIiwRu9VunG
4fg9zEuDbi+8VbQyr3IH5pT8JWA6zaQGhcRKAuFcp2lZvo2dwGmaT0wGhFgR3F4g
mEqKvCXjdJ5gQ43C80YqObcQ+hfzgc6yhPoMQtBVdDMfDK0vlAwUqQ4JcqPOyrok
cFwzE2ghrYxT9RwZU1AD2AcneFjEPDZswCh0XcoAMwuuxQ4BQuF/aW1FwbIggr12
kSpGF0lKj/tk0TEVu/lGW/AlEsof4raJd+dkvEQ4xFn0wLtoMqXA+nMdlyAUPgO2
0YScXc2Zj4sFIfUOLApwWE43bDt1ylMszSwVeHfdG61KDg7rk3FK0qCbo+rLE8Fy
PquMq5ZNKVfLA4v7k/ym
=wh33
-----END PGP SIGNATURE-----
```
<!-- END SIGNATURES -->

<hr>

#### Using this file

Keybase code-signing allows you to sign any directory's contents, whether it's a git repository,
distributable zip file, or a personal documents folder. It aims to replace the drudgery of:

  1. comparing a zipped file to a detached statement
  2. downloading a public key
  3. confirming it is in fact the author's by reviewing public statements they've made, using it

All in one simple command:

```bash
keybase code-sign verify
```
There are lots of options, including assertions (for automating your checks).

For more info, check out https://keybase.io/_/code-signing .
