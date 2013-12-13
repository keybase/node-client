
path = require 'path'
fs = require 'fs'
log = require './log'

##=======================================================================

exports.PackageJson = class PackageJson

  #------------
  
  constructor : ->
    @path = path.join __dirname, '..', 'package.json'

  #------------

  read : (cb) ->  
    await fs.readFile @path, defer err, data
    if err?
      log.error "cannot open package.json: #{err}"
    else
      try 
        @json = JSON.parse data
        ok = true
      catch e
        log.error "Bad json in package.json: #{e}"
    cb ok

  #------------

  version : () -> @json?.version
  bin : () ->
    for k,v of @json.bin
      return k

##=======================================================================

