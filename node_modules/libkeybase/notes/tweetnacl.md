
# Some Notes on TweetNacl testing and development

- I found it quite useful to test against the Python Ed25519 implementation
  to test interoperability between tweetnacl and standalone ed25519.  For instance,
  I wanted to check the interchangeability of public keys, private keys, and
  signatures.
   - The library I used was this one: https://github.com/warner/python-ed25519
- Here's how I generated a public/private key pair in python, and also a signature:

```python
import ed25519
import binascii
sk,vk = ed25519.create_keypair()
print binascii.hexlify(sk.to_bytes())
print binascii.hexlify(vk.to_bytes())
text = b"here is some text input string that I would like to sign!"
sig = sk.sign(text)
print binascii.hexlify(sig)
print json.dump( [ binascii.hexlify(sk.to_bytes()), binascii.hexlify(vk.to_bytes()), text, binascii.hexlify(sig) ]
```

- Let's say the output is:

```json
["b583929ee68d7ff98fae303307ebe37d1ba3e299e934fff93e42958fa8d077771cf962becea35c090f1a7c5d2ec776aada51db2cb24e9b01e3cf9378fd50dc28", "1cf962becea35c090f1a7c5d2ec776aada51db2cb24e9b01e3cf9378fd50dc28", "here is some text input string that I would like to sign!", "6b1000245e43d880926af664714101d53ee939231ff311fc296b429bb72beb7ce368d971aeb2418b95fcc8d1134bda521a0987ddd57ae8491c48ad3ddf29c809"]
```


- Now you're good to go.  Here's how to verify over in nodeland.

``coffee-script
nacl = require 'tweetnacl'
assert = require 'assert'
data = ["b583929ee68d7ff98fae303307ebe37d1ba3e299e934fff93e42958fa8d077771cf962becea35c090f1a7c5d2ec776aada51db2cb24e9b01e3cf9378fd50dc28", "1cf962becea35c090f1a7c5d2ec776aada51db2cb24e9b01e3cf9378fd50dc28", "here is some text input string that I would like to sign!", "6b1000245e43d880926af664714101d53ee939231ff311fc296b429bb72beb7ce368d971aeb2418b95fcc8d1134bda521a0987ddd57ae8491c48ad3ddf29c809"]
msg = new Uint8Array(new Buffer data[2], "utf8")
badmsg = new Uint8Array(new Buffer data[2]+"XX", "utf8")
vk = new Uint8Array(new Buffer data[1], "hex")
sig = new Uint8Array(new Buffer data[3], "hex")
assert nacl.sign.detached.verify(msg,sig,vk)
assert not nacl.sign.detached.verify(badmsg, sig, vk)
```
