
{gpg} = require './gpg'
{PackageJson} = require './package'

##=======================================================================

exports.version_info = (gpg_version, cb) ->
  pjs = new PackageJson()
  err = null
  lines = []
  unless gpg_version?
    await gpg { args : [ "--version" ] }, defer err, gpg_version
  unless err?
    gpg_v = gpg_version.toString().split("\n")[0...2]
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
