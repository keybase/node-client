{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{make_esc} = require 'iced-error'
{User} = require '../user'
db = require '../db'
util = require 'util'
{env} = require '../env'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "vrfy" ]
      help : "add a proof of identity"
    name = "verify"
    sub = scp.addParser name, opts
    sub.addArgument [ "them" ], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    esc = make_esc cb,   "Verify::run"
    await db.open esc defer()
    await User.load { username : env().get_username() }, esc defer me
    console.log "me: #{util.inspect me, { depth : null }}"
    await User.load { username : @argv.them[0] }, esc defer them
    console.log "them: #{util.inspect them, { depth : null }}"
    #await @fetch_track   esc defer()
    #await @fetch_proofs  esc defer()
    #await @verify_proofs esc defer()
    #await @prompt_ok     esc defer()
    #await @post_track    esc defer()
    #await @write_out     esc defer()
    cb null

##=======================================================================

