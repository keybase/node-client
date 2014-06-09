
mods = [
  require('./web_service')
  require('./util')
  require('./alloc')
  require('./constants')
  require('./base')
  require('./track')
  require('./auth')
  require('./revoke')
  require('./cryptocurrency')
  require('./scrapers/twitter')
  require('./scrapers/github')
  require('./scrapers/generic_web_site')
  require('./scrapers/dns')
]

for m in mods
  for k,v of m
    exports[k] = v
