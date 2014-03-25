
{TwitterProofGen,GithubProofGen} = require './sigs'

#=======================================================

exports.aliases = 
  twitter : "twitter"
  twtr    : "twitter"
  git     : "github"
  github  : "github"
  gith    : "github"

#=======================================================

exports.classes = 
  twitter : TwitterProofGen
  github  : GithubProofGen

#=======================================================

