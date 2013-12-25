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
{prompt_yn} = require '../prompter'
colors = require 'colors'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "vrfy" ]
      help : "verify a user's authenticity"
    name = "verify"
    sub = scp.addParser name, opts
    sub.addArgument [ "them" ], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #----------

  prompt_ok : (warnings, cb) ->
    prompt = if warnings
      log.console.log colors.red "Some remote proofs failed!"
      "Still verify this user?"
    else
      "Are you satisfied with these proofs?"
    await prompt_yn { prompt, defval : false }, defer err, ret
    cb err, ret

  #----------

  run : (cb) ->
    esc = make_esc cb, "Verify::run"
    await db.open esc defer()
    await User.load { username : env().get_username() }, esc defer me
    await me.check_public_key esc defer()

    await User.load { username : @argv.them[0] }, esc defer them
    await them.import_public_key esc defer found
    await them.verify esc defer()

    await them.check_remote_proofs esc defer warnings
    await @prompt_ok warnings.warnings().length, esc defer ok


    console.log found


    #await them.compress esc defer()
    #await @fetch_proofs  esc defer()
    #await @verify_proofs esc defer()
    #await @prompt_ok     esc defer()
    #await @post_track    esc defer()
    #await @write_out     esc defer()
    cb null

##=======================================================================

