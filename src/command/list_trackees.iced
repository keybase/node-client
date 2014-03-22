{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{session} = require '../session'
{make_esc} = require 'iced-error'
{env} = require '../env'
log = require '../log'
{User} = require '../user'
{format_fingerprint} = require('pgp-utils').util

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    T :
      alias : 'text'
      action : 'storeTrue'
      help : 'output in text format; default is JSON'

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "list people you are tracking"
      aliases : [ "trackees" ]
    name = "list-trackees"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ].concat opts.aliases

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"

    if (un = env().get_username())?
      await session.check esc defer logged_in
      await User.load_me {secret : false}, esc defer me
      x = me.list_trackees()
      names = (pj.body.track.basics.username for pj in x)
      console.log names
    cb null

  #-----------------

##=======================================================================

