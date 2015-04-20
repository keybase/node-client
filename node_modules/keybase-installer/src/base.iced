
{Config} = require './config'
os = require 'os'
path = require 'path'

##========================================================================

exports.BaseCommand = class BaseCommand

  constructor : (argv) ->
    @config = new Config argv

  run : (cb) -> cb new Error "unimplemented"


##========================================================================

