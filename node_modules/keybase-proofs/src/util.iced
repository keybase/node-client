
{json_stringify_sorted,bufeq_secure} = require('pgp-utils').util

#----------

exports.json_secure_compare = json_secure_compare = (a,b) ->
  [o1,o2] = (json_stringify_sorted(x) for x in [a,b])
  err = if bufeq_secure((new Buffer o1, 'utf8'), (new Buffer o2, 'utf8')) then null
  else new Error "Json objects differed: #{o1} != #{o2}"
  return err

#----------

