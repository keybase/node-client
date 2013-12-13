
{Base} = require './base'
{add_option_dict} = require './argparse'
log = require '../log'
{Server} = require '../server'
{daemon} = require '../util'
fs = require 'fs'
{Launcher} = require '../launch'

#=========================================================================

exports.Command = class Command extends Base

  #------------------------------

  add_subcommand_parser : (scp) ->
    opts = 
      help : 'launch the server in daemon mode'
    name = 'daemon'
    sub = scp.addParser name, opts
    return [ name ]

  #------------------------------

  run : (cb) ->
    l = new Launcher { @config }
    await l.run defer ok
    cb ok

#=========================================================================
