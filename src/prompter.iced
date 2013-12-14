
read = require 'read'

#========================================================================

class Prompter 

  constructor : (@_fields) -> @_data = {}
  data        : ()         -> @_data
  clear       : (k)        -> delete @_data[k]

  #-------------------

  run : (cb) ->
    err = null
    for k,v of @_fields
      await @read_field k, v, defer err
      break if err?
    cb err

  #-------------------

  read_field : (k,{prompt,password,checker,hint}, cb) ->
    err = null
    ok = false
    first = true

    until ok
      p = if first then (prompt + ": ")
      else (prompt + " (" + hint + "): ")
      first = false

      obj = { prompt : p } 
      if password
        obj.silent = true
        obj.replace = "*"
      if (d = @_data[k])?
        obj.default = d
        obj.edit = true
      await read obj, defer err, res, isDefault
      break if err?
      if not checker or checker res
        @_data[k] = res if not isDefault
        ok = true
    cb err

#========================================================================

exports.checkers = checkers = 
  username : (x) -> x.length >= 4 and x.length <= 12
  password : (x) -> x.length >= 12
  email    : (x) -> (x.length > 3) and (a = x.indexOf('@')) > 0 and x.indexOf('.') > a

d = 
  username : 
    prompt : "Your desired username"
    hint : "between 4 and 12 letters long"
    checker : checkers.username
  password : 
    prompt : "Your passphrase"
    password : true
    checker: checkers.password
    hint : "must be at least 12 letters long"
  email :
    prompt : "Your email"
    hint : "must be a valid email address"
    checker : checkers.email

p = new Prompter d
await p.run defer err
console.log p.data()
p.clear "email"
await p.run defer err
console.log p.data()
