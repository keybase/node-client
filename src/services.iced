
{RedditProofGen,DnsProofGen,TwitterProofGen,GithubProofGen,GenericWebSiteProofGen} = require './sigs'

#=======================================================

exports.aliases = aliases = 
  twtr    : "twitter"
  twitter : "twitter"
  git     : "github"
  github  : "github"
  reddit  : "reddit"
  https   : "generic_web_site"
  http    : "generic_web_site"
  web     : "generic_web_site"
  dns     : "dns"

#=======================================================

exports.aliases_reverse = aliases_reverse = {}

for k,v of aliases
  aliases_reverse[v] = k

#=======================================================

exports.classes = 
  twitter : TwitterProofGen
  github  : GithubProofGen
  generic_web_site : GenericWebSiteProofGen
  dns : DnsProofGen
  reddit : RedditProofGen

#=======================================================

