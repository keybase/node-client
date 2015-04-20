
mods = [
  require('./cmd'),
  require('./stream')
]
for mod in mods
  for k,v of mod
    exports[k] = v