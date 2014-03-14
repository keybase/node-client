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
    b :
      alias : 'binary'
      action: "storeTrue"
      help : "output in binary (rather than ASCII/armored)"
    o :
      alias : 'output'
      help : 'the output file to write the encryption to'
    s:
      alias : "sign"
      action : "storeTrue"
      help : "sign in addition to encrypting"
  }

  #----------

  get_cmd_desc : () ->
    return {
      opts :
        aliases : [ "enc" ]
        help : "encrypt a message and output to stdout or a file"
      name : "encrypt"
    }

  #----------

  output_file : () -> @argv.output
  do_binary : () -> @argv.binary
  do_sign : () -> @argv.sign

  #----------

  do_output : (out, cb) ->
    if out? and not @argv.output? 
      log.console.log out.toString( if @argv.binary then 'utf8' else 'binary' )
    cb null

##=======================================================================

