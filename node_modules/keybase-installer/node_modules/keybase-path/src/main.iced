
pathmod = require 'path'

#================

class Base
  constructor : (args = {}) ->
    {@hooks,@name} = args

  unsplit : (v) ->
    if v.length and v[0].length is 0
      v = v[0...]
      v[0] = pathmod.sep
    pathmod.join v...
  join : (v...) -> pathmod.join v...

  #----------------

  # Noop for everything but XdgPosix
  fallback_to_v1 : () -> @

  #----------------

  get_name : (name) -> name or @name

  #----------------

  cache_dir : (name = null) -> @config_dir(name)
  data_dir : (name = null) -> @config_dir(name)

#================

class Posix extends Base
  constructor : (args...) ->
    super args...
    @sep = pathmod.sep
  split : (x) -> x.split @sep
  home : (opts = {}) ->
    ret = if (f = @hooks?.get_home)? then f(opts) else null
    if not ret? and not opts.null_ok
      ret = process.env.HOME
    if (opts.array and ret?) then @split(ret) else ret
  normalize : (p) -> p
  config_dir_v1 : (name = null) ->
    dirs = @home { array : true }
    if (name = @get_name name)?
      dirs.push("." + name)
    @unsplit dirs
  config_dir : (name) -> @config_dir_v1(name)

#================

# A Posix-style system like OSX or Linux that follows, roughly,
# the XDG specification...
class XdgPosix extends Posix

  # Fallback to v1 of configuration, in which we ignored
  # the XDG specification and just stuck everything in ~/.keybase
  # (oh, life was simple back then!!)
  fallback_to_v1 : () -> new Posix { @hooks, @name }

  config_dir : (name = null) ->
    prfx = process.env.XDG_CONFIG_HOME or @join(@home(), ".config")
    name = @get_name name
    if name? then @join(prfx, name) else prfx

  cache_dir : (name = null) ->
    prfx = process.env.XDG_CACHE_HOME or @join(@home(), ".cache")
    name = @get_name name
    if name? then @join(prfx, name) else prfx

  data_dir : (name = null) ->
    prfx = process.env.XDG_DATA_HOME or @join(@home(), ".local", "share")
    name = @get_name name
    if name? then @join(prfx, name) else prfx

#================

uc1 = (p) -> p[0].toUpperCase() + p[1...]

#================

lst = (v) -> v[-1...][0]

#================

class Win32 extends Base

  split : (x) -> x.split /[/\\]/
  normalize : (p) -> @join @unsplit p

  #-------

  config_dir : (name = null) -> @config_dir_v1(name)

  #-------

  config_dir_v1 : (name = null) ->
    home = @home()
    name or= @name
    if name? then @join(home, name)
    else home

  #-------

  home : (opts = {}) ->
    ret = err = null

    if (f = hooks?.get_home)? then ret = f(opts)

    if ret? then ret = (if opts.array then @split(ret) else ret)
    else if not opts.null_ok
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

_klass = switch process.platform
  when 'win32' then Win32
  when 'linux' then XdgPosix
  when 'darwin' then XdgPosix
  else Posix

#================

_eng = new _klass()

#================

exports.new_eng = (args...) -> new _klass args...

#================

for sym in [ 'split', 'unsplit', 'home', 'normalize', 'join', 'config_dir', 'data_dir', 'cache_dir' ]
  exports[sym] = _eng[sym].bind(_eng)

#================

