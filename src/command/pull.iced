{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{session} = require '../session'
{make_esc} = require 'iced-error'
{env} = require '../env'
log = require '../log'
{User} = require '../user'
req = require '../req'
{prompt_passphrase} = require '../prompter'
{KeyManager} = require '../keymanager'
{E} = require '../err'
{KeyPull} = require '../keypull'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    f :
      alias : "force"
      action : "storeTrue"
      help : "force repull from server even if it's already stored locally"

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "pull your public (& private, if possible) key(s) from the server"
    name = "pull"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ]

  #----------
  
  run : (cb) ->
    await session.login defer err
    unless err?
      kp = new KeyPull { force : @argv.force }
      await kp.run defer err
    cb err

##=======================================================================

