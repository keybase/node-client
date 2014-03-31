
mods = [
  require('./web_service')
  require('./util')
  require('./alloc')
  require('./constants')
  require('./base')
  require('./track')
  require('./auth')
  require('./revoke')
  require('./scrapers/twitter')
  require('./scrapers/github')
  require('./scrapers/generic_web_site')
]

for m in mods
  for k,v of m
    exports[k] = v
