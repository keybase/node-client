
{prng} = require 'crypto'
exports.skip = true

#===============================================================

exports.ObjFactory = class ObjFactory

  #----------------------------

  constructor : () ->
    @_objs = {}
    @_i = 0

  #----------------------------

  dump_all : () -> @_objs

  #----------------------------

  produce : () ->
    key = prng(16).toString 'hex'
    val = [ @_i++, key ]
    @_objs[key] = val
    return { key, val }

  #----------------------------

  modify_some : (n = 2) ->
    i = 0
    for k,v of @_objs
      if (i % n) is 0
        v[0] *= 2
        v[1] += "-yo-dawg"
      i++

#===============================================================

