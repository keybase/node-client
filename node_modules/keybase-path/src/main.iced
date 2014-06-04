
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

  #----------------

  cache_dir : (name = null) -> @config_dir(name)
  data_dir : (name = null) -> @config_dir(name)

#================

class Posix extends Base
  constructor : () ->
    @sep = pathmod.sep
  split : (x) -> x.split @sep
  home : (opts = {}) -> 
    ret = process.env.HOME
    if opts.array then @split(ret) else ret
  normalize : (p) -> p
  config_dir : (name = null) ->
    dirs = @home()
    if name?
      dirs.push("." + name)
    @join dirs...

#================

class Linux extends Posix

  config_dir : (name = null) -> 
    prfx = process.env.XDG_CONFIG_HOME or @join(@home(), ".config")
    if name? then @join(prfx, name) else prfx

  cache_dir : (name = null) ->
    prfx = process.env.XDG_CACHE_HOME or @join(@home(), ".cache")
    if name? then @join(prfx, name) else prfx

  data_dir : (name = null) ->
    prfx = process.env.XDG_DATA_HOME or @join(@home(), ".local", "share")
    if name? then @join(prfx, name) else prfx

#================

uc1 = (p) -> p[0].toUpperCase() + p[1...]

#================

class Darwin extends Posix 

  config_dir : (name = null) ->
    path = [ @home(), "Library", "Application Support" ]
    if name? then path.push uc1(name)
    @join path...

#================

lst = (v) -> v[-1...][0]

#================

class Win32 extends Base

  split : (x) -> x.split /[/\\]/ 
  normalize : (p) -> @join @unsplit p

  #-------

  config_dir : (name = null) -> 
    home = @home() 
    if name? then @join(home, name)
    else home

  #-------

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

_eng = switch process.platform
  when 'win32' then new Win32()
  when 'linux' then new Linux()
  when 'darwin' then new Darwin()
  else new Posix()

#================

for sym in [ 'split', 'unsplit', 'home', 'normalize', 'join', 'config_dir', 'data_dir', 'cache_dir' ]
  exports[sym] = _eng[sym].bind(_eng)

#================

