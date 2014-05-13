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

<!-- summarize version = 0.0.5 -->

<!-- BEGIN SIGNATURES -->
#### Signed by https://keybase.io/chris
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQIcBAABCgAGBQJTcjNYAAoJENIkQTsc+mSQ5ngP/iy1KV3STUJo6D3B8wnoW03u
AdpsTAooO7xREoEIv1LutuhZBAzWSKmgOmWEHVa6R7CLarDmz5NImVODkqrBwhCm
jV+mGKz3EfTGdfpCzOzhwiWV6y9ooPapadgRPKGjyyA8sRqpZd/jU3yvZ/oOi0XZ
/7tYPHKYSSVFnDtRHki4lkqVniSJ4H16lC7p3A7aYRbNJQ9NZRpgYlYf9hwQINzf
1BlPO/IIPbxlI0/QPu4UKrtlN1wsOG04UNeLa8DHJdIAXUhwu3ES8BwlQeI5Pj7h
OPgxODCeN06NUrjZssM9NrckwtB6uTy8NuDaxzI7QhLNrwuZSnU5OauTEzupMKL5
XmAzuNGXt3bhfdOCuS4PB4gJc1GLXSwPTwfAKYhT/JhI/8Owh6rQ+ZBu6sCj/AiR
RVDIdtpn8faxbNhtZrKDJoxXDzvdWKjaSf6O/BKWz4q5gbHIQp97/zOyVyJsH2ut
r3ABOhWmjajNqy2LlcVjQuAGjhlBGQaV3+wJlO9P3I+FXAOo/CRSOJtF2C9AEAAz
PS8B8fDn0f6or6pHFW+wBDuqC6p2ZEliPmu/c3s1HaJdVtmK4nslTnEY0fLTUMuZ
mRaZ8DGSj+QKUCigi+LDqKSqtrnNZ3lK2iWqscawAXh4pvJbsfmdSXJ3yJWnYkF0
DtJoNM+1Q6K5UrCWsE62
=EzNx
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
