{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "vers" ]
      help : "output version information about this client"
    name = "version"
    sub = scp.addParser name, opts
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    pjs = new PackageJson()
    await gpg { args : [ "--versionadf" ] }, defer err, dat
    unless err?
      gpg_v = dat.toString().split("\n")[0...2]
      lines = [ 
        (pjs.bin() + " (keybase.io CLI) v" + pjs.version())
        ("- node.js " + process.version)
      ].concat("- #{l}" for l in gpg_v)
      console.log lines.join("\n")
    cb err

##=======================================================================

