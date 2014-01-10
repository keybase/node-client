
{GPG} = require 'gpg-wrapper'
{env} = require './env'
log = require './log'
util = require 'util'

#============================================================

exports.gpg = (inargs, cb) -> 
  log.debug "| Call to gpg: #{util.inspect(inargs)}"
  inargs.quiet = false if inargs.quiet and env().get_debug()
  (new GPG).run(inargs, cb)

#====================================================================
