
# Certifcates

Version of Node v0.10.26 and above have a pretty good list of root CAs, but 
previous versions don't.  Here we import the list from Node v0.10.26 to earlier
clients.  Note that we're only using these certs for checking https://mydomain.com
style proofs, and *not* for communicating with `api.keybase.io`.

# Generation pipeline:

```
./c_to_js.pl < node_root_certs.h > node_root_certs.js
node node_root_certs.js > node_root_certs.json
```
