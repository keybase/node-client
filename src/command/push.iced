pg = require './push_and_keygen'
{E} = require '../err'
{make_esc} = require 'iced-error'
{add_option_dict} = require './argparse'
{env} = require '../env'
{key_select} = require '../keyselector'

##=======================================================================

exports.Command = class Command extends pg.Command

  OPTS :
    g :
      alias : "gen"
      action : "storeTrue"
      help : "generate a new key"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : []
      help : "push a PGP key from the client to the server"
    name = "push"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    add_option_dict sub, pg.Command.OPTS
    sub.addArgument [ "search" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  check_args : (cb) ->
    err = null
    if @argv.search and @argv.gen
      err = new E.ArgsError "Can't both search and generate; pick one or the other!"
    cb err

  #----------

  prepare_key : (cb) ->
    esc = make_esc cb, "Command::prepare_key"
    if @argv.gen
      # On success, will set @key appropriately, so no need to set it ourselves.
      await @do_key_gen esc defer()
    else
      await key_select {username: env().get_username(), query : @argv.search }, esc defer @key
    cb null

  #----------


##=======================================================================

