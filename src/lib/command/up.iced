{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{Uploader} = require '../uploader'
{Encryptor,PlainEncoder} = require '../file'
{EscOk} = require 'iced-error'
{E} = require '../err'
{constants} = require '../constants'

#=========================================================================

exports.Command = class Command extends Base

  #------------------------------

  constructor : (o) ->
    super o
    @enc = true

  #------------------------------

  OPTS : 
    E : 
      alias : "no-encrypt"
      action : "storeTrue"
      help : "turn off encryption"

  #------------------------------
  
  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ 'upload' ]
      help : 'upload an archive to the server'
    name = 'up'

    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument ["file"], { nargs : 1 }
    return opts.aliases.concat [ name ]

  #------------------------------

  crypto_mode : -> constants.crypto_mode.ENC

  #------------------------------

  make_eng : (d) -> 
    d.blocksize = Uploader.BLOCKSIZE
    klass = if @enc then Encryptor else PlainEncoder
    new klass d

  #------------------------------

  make_outfile : (cb) ->
    @uploader = new Uploader { base : @, file : @infile }
    enc_mode = if @enc then constants.enc_version else 0
    @uploader.set_enc_mode enc_mode
    cb null, @uploader

  #------------------------------
  
  run : (cb) -> 
    esc = new EscOk cb, "Uploader::run"
    @enc = not @argv.no_encrypt
    i2o = { infile : true, outfile : true, @enc }
    await @init2 i2o, esc.check_ok(defer(), E.InitError)
    await @uploader.init esc.check_ok(defer(), E.AwsError)
    await @eng.run esc.check_err defer()
    await @uploader.finish esc.check_ok(defer(), E.IndexError)
    cb true

  #------------------------------

#=========================================================================

