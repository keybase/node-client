
{CipherBase} = require './base'
{Encryptor} = require '../file'
{constants} = require '../constants'

#=========================================================================

exports.Command = class Command extends CipherBase

  #-----------------

  output_filename : () ->
    @argv.output or [ @infn, @file_extension() ].join '.'

  #-----------------

  make_eng : (d) -> new Encryptor d
  crypto_mode : -> constants.crypto_mode.ENC
  
  #-----------------
 
  subcommand : ->
    help : 'encrypt a file'
    name : 'enc'
    aliases : [ 'encrypt' ]
    epilog : 'Act like a unix filter and encrypt a local file'

#=========================================================================

