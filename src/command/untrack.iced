{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{make_esc} = require 'iced-error'
db = require '../db'
{User} = require '../user'
{session} = require '../session'

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
    await User.load { username : @argv.them[0] }, esc defer them
    await me.assert_tracking them, esc defer()
    untrack_obj = them.gen_untrack_obj()
    await me.gen_track_proof_gen { uid : them.id, untrack_obj }, esc defer g
    await session.load_and_login esc defer()
    await g.run esc defer()
    await them.remove_key esc defer()
    log.debug "- run"
    cb null

##=======================================================================

