
mods = [
  require('./tree'),
  require('./mem')
]
for mod in mods
  for k,v of mod
    exports[k] = v
