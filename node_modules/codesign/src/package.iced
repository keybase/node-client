path          = require 'path'
fs            = require 'fs'
package_json  = require '../package.json'

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
    "#{@json.name} v#{@version()} #{process.platform}"

##=======================================================================

