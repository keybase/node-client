
mods = [
  require('./web_service')
  require('./util')
  require('./alloc')
  require('./constants')
  require('./base')
  require('./track')
  require('./auth')
  require('./update_passphrase_hash')
  require('./device')
  require('./revoke')
  require('./cryptocurrency')
  require('./subkey')
  require('./sibkey')
  require('./eldest')
  require('./pgp_update')
  require('./announcement')
  require('./scrapers/twitter')
  require('./scrapers/base')
  require('./scrapers/github')
  require('./scrapers/reddit')
  require('./scrapers/generic_web_site')
  require('./scrapers/dns')
  require('./scrapers/coinbase')
  require('./scrapers/hackernews')
  require('./scrapers/bitbucket')
]

for m in mods
  for k,v of m
    exports[k] = v
