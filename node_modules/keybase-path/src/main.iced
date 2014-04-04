
pathmod = require 'path'

#================

class Base
  constructor : () ->
  unsplit : (v) -> 
    if v.length and v[0].length is 0
      v = v[0...]
      v[0] = pathmod.sep
    pathmod.join v...
  join : (v...) -> pathmod.join v...

#================

class Sane extends Base
  constructor : () ->
    @sep = pathmod.sep
  split : (x) -> x.split @sep
  home : (opts = {}) -> 
    ret = process.env.HOME
    if opts.array then @split(ret) else ret
  normalize : (p) -> p

#================

lst = (v) -> v[-1...][0]

#================

class Insane extends Base

  split : (x) -> x.split /[/\\]/ 
  normalize : (p) -> @join @unsplit p

  home : (opts = {}) ->
    ret = null
    err = if not (e = process.env.TEMP)? then new Error "No env.TEMP variable found"
    else if (p = @split(e)).length is 0 then new Error "Malformed env.TEMP variable"
    else if not (p.pop().match /^te?mp$/i) then new Error "TEMP didn't end in \\Temp"
    else
      if lst(p).toLowerCase() is "local" and not opts.local
        p.pop()
        p.push "Roaming"
      ret = if opts.array then p else @unsplit(p)
      null
    if err? then throw err
    return ret

#================

_eng = if process.platform is 'win32' then (new Insane()) else (new Sane())

for sym in [ 'split', 'unsplit', 'home', 'normalize', 'join' ]
  exports[sym] = _eng[sym].bind(_eng)

#================

