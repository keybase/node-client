{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{session} = require '../session'
{make_esc} = require 'iced-error'
{env} = require '../env'
log = require '../log'
{User} = require '../user'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "pull your private key from the server"
    name = "pull"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ]

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    cb null

  #-----------------

##=======================================================================

