{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
session = require '../session'
{make_esc} = require 'iced-error'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : []
      help : "push a PGP key from the client to the server"
    name = "push"
    sub = scp.addParser name, opts
    sub.addArgument [ "search" ], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #----------

  query_keys : (cb) ->
    await gpg { args : [ "-k", @argv.search[0] ] }, defer err, out
    console.log err
    console.log out.toString()
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @query_keys esc defer()
    await session.login esc defer()
    console.log session.logged_in()
    cb null

##=======================================================================

