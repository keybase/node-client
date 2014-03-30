
{DnsProofGen,TwitterProofGen,GithubProofGen,GenericWebSiteProofGen} = require './sigs'

#=======================================================

exports.aliases = 
  twitter : "twitter"
  twtr    : "twitter"
  git     : "github"
  github  : "github"
  gith    : "github"
  https   : "generic_web_site"
  http    : "generic_web_site"
  web     : "generic_web_site"
  dns     : "dns"

#=======================================================

exports.classes = 
  twitter : TwitterProofGen
  github  : GithubProofGen
  generic_web_site : GenericWebSiteProofGen
  dns : DnsProofGen

#=======================================================

