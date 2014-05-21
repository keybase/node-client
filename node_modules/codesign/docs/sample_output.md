
#### Verify

```
./
  1/                                                                                     x
  1/bar.txt                                                                              -  6000
  1/d1/                                                                                  x
    1/d1/apple.txt    303980bcb9e9e6cdec515230791af8b0ab1aaa244b58a8d99152673aa22197d0   -  633
    1/d1/car.txt      f35ab270f45957f6c65656aefcbc37e799ad19eb454218e2f2e6bf4cd88638e5   -  412
    1/d1/foobar.txt   -> ../foo.txt                                                      x
    1/d1/loop         -> ../                                                             x
  1/d2                -> d1                                                              x
  1/foo.txt           b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c   -  40043
```

#### Ignore Presets

```bash
git     # ignore anything as described by .gitignore files
kb      # ignore anything as described by .kbignore  files
```

#### Ignore

```
/SIGNED.md
```

<!-- END SIGNABLE MANIFEST -->

<!-- BEGIN SIGNATURES -->

##### Signed by https://keybase.io/chris

```
------ BEGIN PGP BULLSHIT ------
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
------ END PGP BULLSHIT -------
```

##### Signed by https://keybase.io/max

```
------ BEGIN PGP BULLSHIT ------
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
opjweqfjioweqf ojwjofe jop wfqpjofwpjofw 
------ END PGP BULLSHIT -------
```

<!-- END SIGNATURES -->

<hr>

#### Using this file

You may:

  1. verify that the current directory matches the manifest above
  2. verify with GPG that the 2 signatures attached are valid
  3. verify with GPG the signers' twitter, github, etc., accounts, so you know exactly who signed this document

All this can happen without trusting webs of trust, public key servers, or even the Keybase server itself.

Here's the command to do it:

```bash
keybase code-sign verify
```

If you are expecting a certain author to have signed this folder, much can be asserted and automated, with no server-side trust.

```bash
keybase dir verify \
  --assert keybase:chris \
  --assert twitter:malgorithms \
  --assert fingerprint:b5bb9d8014a0f9b1d61e21e79
```

And of course you can add your own signature to any directory with:

```bash
keybase code-sign sign
```

For more info, check out https://keybase.io/_/code-signing to see what we're trying to achieve.

