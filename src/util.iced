{fork} = require 'child_process'
path = require 'path'
{constants} = require './constants'
ProgressBar = require 'progress'

#=========================================================================

exports.dict_union = (args...) ->
  out = {}
  for d in args
    out[k] = v for k,v of d
  return out

#=========================================================================

exports.rmkey = (obj, key) ->
  ret = obj[key]
  delete obj[key]
  ret

exports.daemon = (args) ->
  icmd = path.join __dirname, "..", "node_modules", ".bin", "iced"
  fork process.argv[1], args, { execPath : icmd, detatched : true }

# convert from Js -> Unix timestamp
exports.js2unix = (t) -> Math.floor(t/1000)

#=========================================================================

is_dict = (d) -> (typeof d is 'object') and not (Array.isArray d)
exports.purge = purge = (d) ->
  out = {}
  for k,v of d when v?
    out[k] = if is_dict v then purge v else v
  return out

#=========================================================================

exports.make_scrypt_progress_hook = () ->
  bar = null
  prev = 0
  progress_hook = (obj) ->
    if obj.what isnt "scrypt" then #noop
    else 
      bar or= new ProgressBar "- run scrypt [:bar] :percent", { 
        width : 35, total : obj.total 
      }
      bar.tick(obj.i - prev)
      prev = obj.i
  return progress_hook

#=========================================================================

exports.make_email = make_email = (un) -> un + "@" + constants.canonical_host 
exports.make_full_username = make_full_username = (un) -> constants.canonical_host + "/" + un

#=========================================================================

exports.date_to_unixtime = date_to_unixtime = (s) -> ~~(s.getTime()/1000)

#=========================================================================

exports.date_to_unix = (o) ->
  switch typeof(o)
    when 'string' then date_to_unixtime (new Date o)
    when 'number' then o
    when 'object'
      if (o instanceof Date) then date_to_unixtime o
      else null
    else null

#=========================================================================
