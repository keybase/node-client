
sigs = require './sigs'

#=======================================================

exports.aliases = aliases = 
  twtr    : "twitter"
  twitter : "twitter"
  git     : "github"
  github  : "github"
  reddit  : "reddit"
  hackernews : "hackernews"
  https   : "generic_web_site"
  http    : "generic_web_site"
  web     : "generic_web_site"
  dns     : "dns"
  coinbase : 'coinbase'

#=======================================================

exports.aliases_reverse = aliases_reverse = {}

for k,v of aliases
  aliases_reverse[v] = k

#=======================================================

exports.classes = 
  twitter : sigs.TwitterProofGen
  github  : sigs.GithubProofGen
  generic_web_site : sigs.GenericWebSiteProofGen
  dns : sigs.DnsProofGen
  reddit : sigs.RedditProofGen
  coinbase : sigs.CoinbaseProofGen
  hackernews : sigs.HackerNewsProofGen

#=======================================================

