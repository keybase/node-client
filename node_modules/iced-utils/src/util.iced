assert = require 'assert'

#=========================================================

exports.Warnings = class Warnings
  constructor : () -> @_w = []
  push : (args...) -> @_w.push args...
  warnings : () -> @_w

#=========================================================

exports.bufeq_fast = (x,y) ->
  return true if not x? and not y?
  return false if not x? or not y?
  return false unless x.length is y.length
  for i in [0...x.length]
    return false unless x.readUInt8(i) is y.readUInt8(i)
  return true

#-----

exports.bufeq_secure = bufeq_secure = (x,y) ->
  ret = if not x? and not y? then true
  else if not x? or not y? then false
  else if x.length isnt y.length then false
  else
    check = 0
    for i in [0...x.length]
      check += (x.readUInt8(i) ^ y.readUInt8(i))
    (check is 0)
  return ret

#-----

exports.streq_secure = (x,y) ->
  bufeq_secure (bufferify x), (bufferify y)

#=========================================================

exports.bufferify = bufferify = (s) ->
  if Buffer.isBuffer(s) then s
  else if typeof s is 'string' then new Buffer s, 'utf8'
  else throw new Error "Cannot convert to buffer: #{s}"

#=========================================================

exports.katch = katch = (fn) ->
  ret = err = null
  try ret = fn()
  catch e then err = e
  [err, ret]

#=========================================================

exports.akatch = akatch = (fn, cb) ->
  asyncify (katch fn), cb

#=========================================================

exports.athrow = (err, cb) -> cb err
exports.asyncify = asyncify = (args, cb) -> cb args...
   
#=========================================================

exports.a_json_parse = (s, cb) -> 
  akatch ( () -> JSON.parse s), cb

#=========================================================

exports.buffer_to_ui8a = buffer_to_ui8a = (b) ->
  l = b.length
  ret = new Uint8Array l
  for i in [0...l]
    ret[i] = b.readUInt8 i
  ret

#=========================================================

exports.ui32a_to_ui8a = ui32a_to_ui8a = (v, out = null) ->
  out or= new Uint8Array v.length * 4
  k = 0
  for w in v
    out[k++] = (w >> 24) & 0xff
    out[k++] = (w >> 16) & 0xff
    out[k++] = (w >> 8 ) & 0xff
    out[k++] = (w      ) & 0xff
  out

#=========================================================

exports.ui8a_to_ui32a = ui8Ga_to_ui32a = (v, out = null) ->
  out or= new Uint32Array (v.length >> 2)
  k = 0
  for b,i in v by 4
    tmp = (b << 24) + (v[i+1] << 16) + (v[i+2] << 8) + v[i+3]
    out[k++] = tmp
  out

#=========================================================

exports.unix_time = () -> Math.floor(Date.now()/1000)

#=========================================================

exports.is_sorted = is_sorted = (list, sort_fn) ->
  if not sort_fn?
    sort_fn = (a,b) -> ("" + a).localeCompare("" + b)
  for i in [0...(list.length-1)]
    j = i + 1
    if sort_fn(list[i],list[j]) > 0
      return false
  return true

#=========================================================

exports.json_stringify_sorted = (o, opts) ->
    # opts: 
    #  sort_fn: a comparison function for sorting keys
    #  spaces:  null for compressed JS;
    #           number for number of spaces
    #           string for literal
    opts     = opts or {}
    sort_fn  = opts.sort_fn or null
    spaces   = opts.spaces  or null
    lb       = if opts.spaces? then "\n" else ""
    if (typeof spaces) is "number"
      spaces = (" " for i in [0...spaces]).join ""

    space_it = (depth) ->
      if not spaces? then return ""
      return "\n" + (spaces for i in [0...depth]).join ""

    json_safe = (os, depth) ->
      # this inner function should only be called on an object
      # which has been pull from a JSON parse; no error checking
      if Array.isArray os
        s = "[" + (json_safe(v,depth+1) for v in os).join(',') + "]"
      else if (typeof os) is "object"
        if not os
          s = JSON.stringify os
        else
          sp   = space_it(depth)
          spp  = space_it(depth+1)
          keys = (k for k of os)

          if sort_fn?
            keys.sort sort_fn
          else
            keys.sort()
          s = "{" + ( spp + JSON.stringify(k) + ":" + json_safe(os[k],depth+1) for k in keys).join(',') + sp + "}"
      else
        s = JSON.stringify os
      return s

    str = JSON.stringify o
    if str is undefined
      return str
    else
      o2 = JSON.parse str
      return json_safe o2, 0

#=========================================================

exports.obj_extract = obj_extract = (o, keys) ->
  ret = {}
  (ret[k] = o[k] for k in keys)
  ret

#=========================================================

exports.base64u = 

  encode : (b) ->
    b.toString('base64')
      .replace(/\+/g, '-')      # Convert '+' to '-'
      .replace(/\//g, '_')      # Convert '/' to '_'
      .replace(///=+$///, '' )  # Remove ending '='

  decode : (b) ->
    b = (b + Array(5 - b.length % 4).join('='))
      .replace(/\-/g, '+') # Convert '-' to '+'
      .replace(/\_/g, '/') # Convert '_' to '/'
    new Buffer(b, 'base64');

  verify : (b) -> /^[A-Za-z0-9\-_]+$/.test b

#=========================================================

exports.assert_no_nulls = assert_no_nulls = (v) ->
  ok = true
  (ok = false for e in v when not e?)
  unless ok
    console.error "Found 1 or more nulls in vector: "
    console.error v
    assert false

#=========================================================

# Chain callback cb1 and cb2.
# Call cb1 first, and throw away whatever it calls back with.
# Then call cb2, and pass it the args the chain was called back
# with.  This is useful for doing a cleanup routine before 
# something exits.
exports.chain = (cb2, cb1) -> (args...) -> cb1 () -> cb2 args...

#=========================================================

# Take a union of the n dictionaries, from left to right.
# Last writer wins, with no recursion
exports.dict_union = dict_union = (args...) ->
  out = {}
  for d in args
    out[k] = v for k,v of d
  return out

#=========================================================

# Merge the n dictionaries, from left to right.
# Last writer wins, with recursion.
exports.dict_merge = (args...) ->

  isdict = (x) -> x and (typeof(x) is 'object') and not(Array.isArray(x)) and not(Buffer.isBuffer(x))

  clone = (x) ->
    if typeof(x) isnt 'object' then x
    else if Array.isArray(x) then x[0...]
    else
      out = {}
      for k,v of x
        out[k] = clone(v)
      return out

  m = (y, x) ->
    for k,v1 of x
      v2 = y[k]
      if not isdict(v1) then y[k] = v1
      else if isdict(v2) then m(v2, v1)
      else y[k] = clone v1
  out = {}
  for d in args
    m(out, d)
  return out

#=========================================================

# output a buffer in XXD output (like the unix utility)
exports.xxd = xxd = (buf, opts = {}) ->
  q = opts.q or 8 # number of quarters per line
  p = opts.p or 7 # amount of padding in line prefixes
  buf = buf.toString 'hex'
  quartets = (buf[i...(i+4)] for i in [0...buf.length] by 4)
  lines = (quartets[i...(i+q)].join(' ') for i in [0...quartets.length] by q)
  pad = (s, n) -> ('0' for [0...(n - s.length)]).join('') + s
  v = for line, i in lines
    pad((i*2*q).toString(16), p) + ": " + line
  v.join("\n")

#=========================================================

