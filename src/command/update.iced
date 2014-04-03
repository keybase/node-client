{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{version_info} = require '../version'
{run} = require 'iced-spawn'
path = require 'path'
{env} = require '../env'

##=======================================================================

rewrite = (s) -> s.replace(/-/g, "_")

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    n:
      alias : "npm"
      help : "an alternate path for NPM"
    u :
      alias : "url"
      help : "specify a URL prefix for fetching"
    C :
      alias : "skip-cleanup"
      action : "storeTrue"
      help : "Don't cleanup temporary stuff after install"
    c : 
      alias : "cmd"
      help : "the command to run"
    p : 
      alias : "prefix"
      help : "the prefix to install to"

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ ]
      help : "update the keybase client software"
    name = "update"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    log.info "Attempting software upgrade....."

    # Add our current location onto the front of the page
    process.env.path = [ path.dirname(process.argv[1]) , process.env.path  ].join(":")

    name = (@argv.cmd or "keybase-installer") 
    args = []
    args.push("-g", g) if (g = env().get_gpg_cmd())?
    args.push("-O") if env().get_no_gpg_options()
    args.push("-d") if env().get_debug()

    for a in [ "npm", "url", "prefix" ]
      args.push("--#{a}", v) if (v = @argv[rewrite(a)])?
    for a in [ "skip-cleanup" ]
      args.push("--#{a}") if (v = @argv[rewrite(a)])

    inargs = { args, name }
    await run inargs, defer err, out
    cb err

##=======================================================================

