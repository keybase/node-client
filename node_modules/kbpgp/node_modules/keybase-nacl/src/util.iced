
#---------------------------------------------------------
# Constant-time buffer comparison
#
exports.bufeq_secure = (x,y) ->
  ret = if not x? and not y? then true
  else if not x? or not y? then false
  else if x.length isnt y.length then false
  else
    check = 0
    for i in [0...x.length]
      check |= (x.readUInt8(i) ^ y.readUInt8(i))
    (check is 0)
  return ret