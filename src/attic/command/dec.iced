{CipherBase} = require './base'
{Decryptor} = require '../file'
{constants} = require '../constants'

#=========================================================================

exports.Command = class Command extends CipherBase
   
  #-----------------

  output_filename : () ->
    if not (o = @argv.output)? then @strip_extension @infn
    else if o isnt '-' then o
    else null

  #-----------------
 
  make_eng : (d) -> new Decryptor d
  crypto_mode : -> constants.crypto_mode.DEC
  
  #-----------------
 
  subcommand : ->
    help : 'decrypt a file'
    name : 'dec'
    aliases : [ 'decrypt' ]
    epilog : 'Act like a unix filter and decrypt a local file'

#=========================================================================
