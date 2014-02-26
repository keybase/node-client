pg = require './push_and_keygen'
{E} = require '../err'
{make_esc} = require 'iced-error'
{add_option_dict} = require './argparse'
{prompt_yn} = require '../prompter'

##=======================================================================

exports.Command = class Command extends pg.Command

  OPTS : 
    p:
      alias : "push"
      action : "storeTrue"
      help : "true if we should push"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : ['gen', 'generate']
      help : "generate a new PGP public key and optionally push it to the server"
    name = "keygen"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    add_option_dict sub, pg.Command.OPTS
    return opts.aliases.concat [ name ]

  #----------

  check_args : (cb) ->
    err = null
    if @argv.search and @argv.gen
      err = new E.ArgsError "Can't both search and generate; pick one or the other!"
    cb err

  #----------

  should_push : (cb) ->
    err = ret = null
    if @argv.push then ret = true
    else
      await prompt_yn { prompt : "Push your public key to the server?", defval : true }, defer err, ret
    cb err, ret 

  #----------

  should_push_secret : (cb) ->
    err = ret = null
    if @argv.secret then ret = true
    else
      await prompt_yn { prompt : "Push your encrypted private key to the server?", defval : true }, defer err, ret
    cb err, ret

  #----------

  prepare_key : (cb) ->
    await @do_key_gen defer err
    cb err

  #----------


##=======================================================================

