{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "unverify" ]
      help : "untrack this user"
    name = "untrack"
    sub = scp.addParser name, opts
    sub.addArgument ["them"], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    esc = make_esc cb, "Untrack::run"
    log.debug "+ run"
    await db.open esc defer()
    await User.load_me esc defer me

    log.debug "- run"
    cb err

##=======================================================================

