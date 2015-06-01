##### Signed by https://keybase.io/oconnor663
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2

iQEcBAABCAAGBQJVgZ+1AAoJEHGHa2itSC0y2XoIAMOL0QNws/4myqK56q4JKIbx
2dewO1mT8mRPO4B6gsQ4nq6Y7Z+CMWpDvqFIC9gBceH6iKK1IOiU+uswxTyHmwTX
YZpXdbf5Lm8xmz/dlOkigK95fS2Mr6q5naK114n5jUWwCMSlpl9Faw6JNE6P1mv3
f5N6DqfzQdq5GfSiu1xE0I+WuVkwOwptRbyGVfUCyGySfnOWfpHHxUBUfVe55DBk
QaCcRjg/ew2hOvzzTva77TZvch5N9VWmGAQAob1A9SAZrnLWqTabd3bUwXsSR7Ds
wx0apLlJ8G9MaGOgt3LRba6HDCRLAapJW1S14y++ibU+mqJttQexKv2pmky1Kc0=
=Jrzg
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size    exec  file                                          contents                                                        
              ./                                                                                                            
6202            chain_tests.json                            4c46413927448ca60dba392e236b01177fa2d123bb2cc045fccd91df9912e12b
                chains/                                                                                                     
6051              bad_prev_chain.json                       53f930afd490f739b57d1de35bfb18c0e3dc9e4163a1eb898fce8bdcc98f6842
6051              bad_reverse_signature_chain.json          06940369198a81f6f89bc86dcfd21261b54d397d0ce1cb53b8ec36c522b16ed1
6051              bad_seqno_chain.json                      a411e254fdf9af78d5de5dd8036fb649ce7756fa930edd42a36110c0ab863826
8252              bad_signature_chain.json                  2d0975006ea357e9e0f64557044eed5659ffb037584e2fdc41a1b73c4c237fb6
1607              bad_uid_chain.json                        b9092ab9f79b6359a0df90eb827e18e818377f45cd30f201f76b5f0ada1bbd29
1626              bad_username_chain.json                   58e0e004357f39415b00e1efaf482cc09e8e15cebf3b8b10070f63c85fc9f7d0
1940              empty_chain.json                          3cc56d941437a5120dae27cbba205a02587830dd08fd11dcc6cc05ea18ceb616
47466             example_revokes_chain.json                d693741bfb17fbdd0bd5da570828f9c2d2c0e7676548ad3295c07e1c8b421c64
6001              expired_key_chain.json                    c2733bb8a55f5abb2c712fa2d84740cc36974237a14a3ca388c582570afbb7dd
                  inputs/                                                                                                   
400                 bad_prev_chain.cson                     a315fa2626056325f2e2961ac5fa755c1fd77f1d8e1096d2f146e4972e897be6
309                 bad_seqno_chain.cson                    f0f039ff7f04fc8b6aaa0c05c8e9e777782d136258a04e6fefd8544b3ba1fd0f
206                 bad_uid_chain.cson                      b17a1a982c5a84e3fe1a0a4d1e089887a4d7fb3450571177cdbf8544ff46c1be
191                 bad_username_chain.cson                 0c265be0f1673b86ab7d47a73dac5741b534c4f2412e40fb07c63d24d849896a
2571                example_revokes_chain.cson              1fa7bd01611ffd4e84b6ab6ec551711b136c14dd0a08a55922821fe1044fdf56
302                 expired_key_chain.cson                  1cb759331e75f16e1057882fa15f114d86184b61e1bb84eb340a47308f6ce057
541                 signed_with_revoked_key_chain.cson      62d9b4bcef4c86ebd64419e844d4c848be9f469b55ee78abb3a4beb8cab96ac9
160                 simple_chain.cson                       fc5d18080e832797349566cdf512fa46d28ede8d291d85f855fd9c9eafbdcf8a
285                 two_link_chain_for_manual_hacking.cson  8659c7b477321c83f3102f03afd1b480099016ff7ce4216f13636b563c41eda7
173515            jack_chain.json                           509e95fc94e879214ead59039cdeea21f2e52b6826bf0739db48c7862e9605a8
170443            jack_chain_missing_first_link.json        c107107129b9013c0974ca7f83732c905557635df2da8e31ff2a0fbe36b8a395
168376            jack_chain_substitute_first_link.json     ec3d87af3c5c39ead8215fb23fad34647a76dccdd9ae0394acc91fc984979f28
6051              mismatched_ctime_chain.json               47e9d2aa2dc77dd8827fb3109581131ec5b853ff5024b282ac2215c73c0af680
8244              mismatched_fingerprint_chain.json         d49b5b9b19b84b287d7d3baadca941acf102e553acb13dfbc046ac53841f8c21
8280              mismatched_kid_chain.json                 8b238dd8ddf942341a3b1f213f2b0052e1e519a73e37ff3590e06fdbe11bce11
7375              missing_kid_chain.json                    a5959e4f56b209c9d8071b924115747a31c5e5091b5b4c06d5d694bbf1af591a
7391              missing_reverse_kid_chain.json            cf5eb200d78afd221e11674581a574d82225286aff15f9d5f8739554c564bc04
43316             ralph_chain.json                          c4da3be30f814464b94d27b19fc51be5907a702094b55c540903dc4f9f1d9fd8
12536             signed_with_revoked_key_chain.json        55ac1ea124f7e9bb2473035be106b1718e288527a3583fd711c726185a047051
1607              simple_chain.json                         138d7ac6ba3dff9d210e90101156cc399de6d070eb742eecf10ee2cc9e32b890
1600    x       generate.py                                 c779ea5e69a2af581c42fb288b10dd2810c93326cf68d6bcedc19efe44c3f595
                go/                                                                                                         
699805            testvectors.go                            9a43ccbc406879d001f2c6360f5851e4f18dc7f418cd4c9f4894c9e9b1a37ff8
                js/                                                                                                         
2166              main.js                                   7968e06b237e4c26bf7e5fdb7a3de1b68b3cc0bfda17079b0974930becebbeea
322             package.json                                7b41b4a2db606766aecf11c92e67f10909e9e2869f0885b171d89c943b3d0e89
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