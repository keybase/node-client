
exports.merkle = 
  leaf : require('./merkle/leaf')
  pathcheck : require('./merkle/pathcheck')

# Export all of these modules as namespace extensions
exports[k] = v for k,v of {
  constants : require('./constants')
  err : require('./err')
  kvstore : require('./kvstore')
  assertion : require('./assertion')
}

# Export the exports of these modules to the top level
mods = [
  require('./sigchain/sigchain')
]
for mod in mods
  for k,v of mod
    exports[k] = v
