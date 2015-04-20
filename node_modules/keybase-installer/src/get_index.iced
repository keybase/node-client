
{make_esc} = require 'iced-error'
{chain,unix_time,a_json_parse} = require('iced-utils').util
{constants} = require './constants'
log = require './log'

##========================================================================

exports.GetIndex = class GetIndex

  constructor : (@config) ->

  #--------------------------

  fetch : (cb) ->
    await @config.request "/sig/files/#{@config.key_version()}/index.asc", defer err, res, @_signed_index
    cb err

  #--------------------------

  verify : (cb) ->
    now = unix_time()
    await @config.oneshot_verify { which : 'index', sig : @_signed_index }, defer err, @_index
    err = if err? then err
    else if not (t = @_index.timestamp)? then new Error "Bad index; no timestamp"
    else if (a = now - t) > (b = constants.index_timeout) then new Error "Index timed out: #{a} > #{b}"
    else if not @_index.keys?.latest? then new Error "missing required field: keys.latest"
    else if not @_index.package?.latest? then new Error "missing required field: package.latest"
    else null
    cb err
    
  #--------------------------

  run : (cb) -> 
    log.debug "+ GetIndex::run"
    esc = make_esc cb, "GetIndex::run"
    await @fetch esc defer()
    await @verify esc defer()
    @config.set_index @_index
    log.debug "- GetIndex::run"
    cb null
  
##========================================================================

