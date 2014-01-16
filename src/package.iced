
path = require 'path'
fs = require 'fs'
log = require './log'
package_json = require '../package.json'
{constants} = require './constants'

##=======================================================================

exports.PackageJson = class PackageJson

  #------------
  
  constructor : ->
    @json = package_json

  #------------

  version : () -> @json?.version
  bin : () ->
    for k,v of @json.bin
      return k

  #------------

  identify_as : () ->
    "#{constants.client_name} v#{@version()}"

##=======================================================================

