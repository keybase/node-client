{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferInStream} = require('iced-spawn')
{master_ring} = require '../keyring'
{make_esc} = require 'iced-error'
{dict_union} = require '../util'
{User} = require '../user'
{env} = require '../env'
ee = require './encrypt_and_email'

##=======================================================================

exports.Command = class Command extends ee.Command

  #----------

  OPTS : dict_union ee.Command.OPTS, {
    S:
      alias : "no-sign"
      action : "storeTrue"
      help : "don't sign (sign by default)"
  }

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "enc" ]
      help : "verify a user's authenticity and optionally track him"
    name = "encrypt"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "them" ], { nargs : 1 , help : "the username of the receiver" }
    sub.addArgument [ "file" ], { nargs : '?', help : "the file to be encrypted" }
    return opts.aliases.concat [ name ]

  #----------

  do_sign : () -> not(@argv.no_sign)

  #----------

  do_output : (out, cb) ->
    if out? and not @argv.output? 
      log.console.log out.toString( if @argv.binary then 'utf8' else 'binary' )
    cb null

##=======================================================================

