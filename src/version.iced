
{gpg} = require './gpg'
{PackageJson} = require './package'

##=======================================================================

exports.version_info = (cb) ->
  pjs = new PackageJson()
  err = lines = []
  await gpg { args : [ "--version" ] }, defer err, dat
  unless err?
    gpg_v = dat.toString().split("\n")[0...2]
    lines = [ 
      (pjs.bin() + " (keybase.io CLI) v" + pjs.version())
      ("- node.js " + process.version)
    ].concat("- #{l}" for l in gpg_v).concat [
      ("Identifies as: '" + pjs.identify_as() + "'")
    ]
  cb err, lines

##=======================================================================

exports.platform_info = () ->
  d = {}
  for k in [ "versions", "arch", "platform", "features" ]
    d[k] = process[k]
  return d

##=======================================================================
