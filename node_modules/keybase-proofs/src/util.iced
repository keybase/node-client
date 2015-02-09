
{json_stringify_sorted,bufeq_secure} = require('pgp-utils').util

#----------

exports.json_secure_compare = json_secure_compare = (a,b) ->
  [o1,o2] = (json_stringify_sorted(x) for x in [a,b])
  err = if bufeq_secure((new Buffer o1, 'utf8'), (new Buffer o2, 'utf8')) then null
  else new Error "Json objects differed: #{o1} != #{o2}"
  return err

##-----------------------------------------------------------------------

# Copied from iced-utils, so as not to introduce a dependency
# on a library that's used mainly in node.
exports.Lock = class Lock
  constructor : ->
    @_open = true
    @_waiters = []
  acquire : (cb) ->
    if @_open
      @_open = false
      cb()
    else
      @_waiters.push cb
  release : ->
    if @_waiters.length
      w = @_waiters.shift()
      w()
    else
      @_open = true
  open : -> @_open

##-----------------------------------------------------------------------

exports.space_normalize = (s) -> s.split(/[\r\n\t ]+/).join(' ')

##-----------------------------------------------------------------------
