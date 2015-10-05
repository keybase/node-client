##### Signed by https://keybase.io/oconnor663
```
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v2

iQEbBAABAgAGBQJWEqNGAAoJEHGHa2itSC0ylgEH9RBT6xh08BZz3sK55ETpALvN
Sr5qReHHiGHFdgJop2gtbWVgYNdb+Z/ozPN+uwhL/Kaz5D+V/jr0rEK/cCDzNicS
E0ITof1VVlfqnEjJj09R+vOMSEhzoyIV+t7RnaZn2qNyTo7TS2sxZc5zFoYFH4pq
G+yujl0mH1ZwXdpsWrCpB1ARg8IbnMOH1topr24MVBEa+mbUorVN1NiaSHzNHvgy
gA2HfPeS4v9XoF2FV3nqL9WsnozMCvzmEO6ZIe49zUZY+DybTMsXfJUTWy5F4dY4
GlQkRqTWKa/UtbTdXdOZix/4OJ0dzkF9Js8uSYx76TETd+fSMOEOMk985sCMUA==
=IEzk
-----END PGP SIGNATURE-----

```

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
size    exec  file                            contents                                                        
              ./                                                                                              
67              .gitignore                    5e89d4014d03a0f7f21f1429ab57b662f835214ac9bc4512285fed2982011191
3182            CHANGELOG.md                  3e4f315fb907781d2fa7cf54cf72ebf7a0078b8d5256dc55a606fc840a91c7c5
1484            LICENSE                       20a8a5de57bfaf6870517c52265d4469770a23cbc1af85eb9973ce639b0abff2
1353            Makefile                      d7f684e836240e402e48f131cf4a8fe5efb722156cb8587f5e25288cfb812f2d
109             README.md                     f2dd5d8192cff83f9c44a3e56779977bfe82725df259970a5c2d5396e6f87e13
                browser/                                                                                      
6045              libkeybase.js               92b7c0f624b90754f89aa55f19a7cd6d45dc22cdac2c8e5ed9a353e26d498c89
3973            data                          ac1fb9d3a854c92f33c833ee8a263c640040092ec20dddede7f1bc67770dea36
                examples/                                                                                     
2768              app1.iced                   88c574445bf29fdc74e899f4c7fff14933fb6b1d9a6ee788387dc2586d4dd51b
3983              encrypt.iced                319601683b74ce376e69da3a1f04c5317ce39a5c31a3c36ad90fc66dafcddabc
1730              recruit.iced                645be6aa67bfe992133503feddb66b9dc0c551dd4744ac3335f3230ceadcbcf4
1232              release.iced                89c83622eb0099f732de4c026c7d807998df328d8d364ec9cffbe179c398c98c
1249              trigger1.json               540beed96b0b13697bd7222a52fb48288ee4e99ba7ea328ef55506604e8bc1e6
                lib/                                                                                          
8627              assertion.js                7d5c2eb9951c87425450a11deea9d98533e48d5dde287a49c39198ed9f90c287
21312             assertion_parser.js         d092db7012e31dea39a87232d2162ace9bf3f4c86550453471dc6e6c61823670
267               constants.js                7cb39b3933926960bd762fb9c6251eb67d36dfb1c62925739588510a43bbfb2b
2712              err.js                      b6ca0b3731e1cbb5902940367679e9213ef857082a8568569ce141bd50d75d41
22073             kvstore.js                  40d061e72d572746b5d557d28e16ed43a4cd23da459e004382e2d15dab855702
625               main.js                     c046e0c31a2b087f1dc56a373b46f16691ce3065d4cd0c9ca0fa5c62bfb233c0
                  merkle/                                                                                     
6356                leaf.js                   b22f0873a9f0e9adb00be96549f25a637af02dff88b34e8392d9d46f4835c0c3
16991               pathcheck.js              781c7078bfa40c5196036c8a886e7ff217f6bb7111ff2c30df61e2184400af2b
                  sigchain/                                                                                   
56729               sigchain.js               be9d400b161fa8867cfba8ef4c75b5f24d9992b8a39f81f5d6ddd3dcaab99687
                notes/                                                                                        
2129              tweetnacl.md                099fac68f7caebd05b6060781e7fcfb32726309bb4bd67aa35b10134a280e049
1138            package.json                  628e78f8ab54b765f36ec2334f5c37937489006ae3b35f65fd620587b05c6c06
                src/                                                                                          
4407              assertion.iced              fac9d95f8915318ec94dcd9f57f0f6a1b65b210429e6a5f6ac2ad8d33b97cd10
634               assertion_parser.jison      65624a141081113074e6c778af7df8fad6769d3c5b2fb96e8edcd31444f8706f
150               constants.iced              51334d9c4a8809755185ffa9363bc2bfd40582a78b18bf048136961b4385dfae
2590              err.iced                    1c5a05067c904716368ed055186131c58691d5183a584f6a74677c882e7b441b
6948              kvstore.iced                53ebce5a6b584fc9977c6502554a0df97463a94416de4eacbb572fafe83f052d
466               main.iced                   0d36dd68f0281e58d0269395bcd9b2ef4d6d2ffbd69307e292b5aa14e646b4df
                  merkle/                                                                                     
3857                leaf.iced                 5de4556aff8642d7bdfc39cb0edff1acbeb693ce040faa272fb4cf8fe3b6092d
4470                pathcheck.iced            23650aa2a4db7497e55b23c3f0ff0cdefeb60ff8f0363a6f4a1348405e9f5cc8
                  sigchain/                                                                                   
30446               sigchain.iced             111175e79cbc8870bb90798409df4b58dbd10fc1ca0fbd025f35570ff8d5b992
                test/                                                                                         
                  browser/                                                                                    
287                 index.html                e31387cfd94034901e89af59f0ad29a3e2f494eb7269f1806e757be21b3cf33e
258                 main.iced                 a37b688cc46a4cfe2eee5892f556d4a4a96b2fcbe59e8e50e935bbc57262f16b
                  files/                                                                                      
305797              29_merkle_pathcheck.iced  eef8556b0450553b841643bd478ad2cd73e4ffd266f94be3262549606a1ea04c
4706                30_merkle_leaf.iced       2ed24fd02ac4d9c39149d974d774760448db6f4a600fd9adbb3b1b35e0d0000c
7330                31_sigchain.iced          9bb351dcee7b2655707e16c5537f1713fcbfabfad069fd9b6de42442aa46cc64
5624                32_kvstore.iced           90bacb5973649246d91f959d64c6cb6a7d52e1a2784ccd4363997f2ef5ef17a2
2704                33_assertion.iced         73f0b3beef768b9d003d7273f8917a2ada71b8d13b46cdf87d1eaa11c73340e2
52                run.iced                    8e58458d6f5d0973dbb15d096e5366492add708f3123812b8e65d49a685de71c
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