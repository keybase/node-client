badnode = require '../..'

test = (v, err) ->
  (T, cb) ->
    e2 = badnode.check_node v
    if not err? then T.no_error e2
    else if err?
      T.assert e2?, "got an error bad"
      T.assert e2.message.indexOf(err) >= 0, "error message was found"
    cb()

d =
  "0.6.44"  : "out of date"
  "0.8.44"  : "out of date"
  "0.10.19" : "out of date"
  "0.10.31" : "known to crash"
  "0.10.32" : null
  "0.11.1"  : null

for k,v of d
  for prefix in ["", "v"] 
    ( (k2,v2,p2) -> exports["test-#{p2}#{k2}"] = test (p2+k2), v2)(k,v,prefix)
