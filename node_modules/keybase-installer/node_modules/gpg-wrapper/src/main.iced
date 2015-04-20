modules = [
  require("./err")
  require("./gpg")
  require("./parse")
  require("./colgrep")
]
for m in modules
  for k,v of m
    exports[k] = v

# Export keyring stuff in a namespace
exports.keyring = require('./keyring')
