
path = require 'path'
fs = require 'fs'
log = require './log'
util = require 'util'
mkdirp = require 'mkdirp'

#=========================================================================

exports.Config = class Config

  #-------------------

  constructor : (@filename) ->
    @json = null
    @loaded = false
    @cache = {}

  #-------------------

  open : (cb) ->
    err = null
    await fs.exists @filename, defer @found
    if not @found
      log.warn "No config file found; tried '#{@filename}'"
      log.warn "Run 'keybase setup' to make a new config file"
    else
      await @load defer err
    cb err

  #-------------------

  write : (cb) ->
    dat = JSON.stringify @json, null, "    "
    await fs.writeFile @filename, dat, { mode : 0o600 }, defer err
    ok = true
    if err?
      log.error "Error writing to #{@filename}: #{err}"
      ok = false
    cb ok

  #-------------------

  set : (key, val) ->
    parts = key.split "."
    @json = {} unless @json?
    d = @json
    for p in parts[0...(parts.length-1)]
      d[p] = {} unless d[p]?
      d = d[p]
    d[parts[parts.length-1]] = val

  #-------------------

  load : (cb) ->
    err = null
    
    await fs.readFile @filename, defer err, file
    if err?
      log.error "Cannot read file #{@filename}: #{err}"
    else
      try
        @json = JSON.parse file
      catch e
        log.error "Invalid json in #{@filename}: #{e}"
        err = e

    unless err?
      for key in [ ]
        unless @json?[key]?
          log.error "Missing JSON component '#{key}' in #{@filename}" 
          err = new E.ConfigError "missing component '#{key}'"

    log.warn "Failed to load config" if err?

    cb err

  #-------------------

  tmpdir : () ->
    @_tmpdir = @config?.json?.files?.dir or (path.join path.sep, "tmp", "mkb") unless @_tmpdir?
    @_tmpdir

  #-------------------

  _get_file : (which) -> 
    unless (f = @cache[which])?
      f = @config?.json?.files?[which] or path.join(@tmpdir(), "keybase.#{which}") 
      @cache[which] = f
    f

  #-------------------

  sockfile : () -> @_get_file "sock"
  pidfile  : () -> @_get_file "pid"
  logfile  : () -> @_get_file "log"

  #-------------------

  pidfile : (cb) ->
    @_pidfile = @config?.json?.files?.pid or (path.join @tmpdir(), "keybase.pid") unless @_pidfile?
    @_pidfile

  #-------------------

  make_tmpdir : (cb) ->
    n = @tmpdir()
    await mkdirp n, defer err
    if err?
      log.error "Error making temp dir #{n}: #{err}"
    cb (not err?)

  #-------------------

  file_extension : () ->
    @json.file_extension or "kbs"

  #-------------------

  obj : () -> @json

  #-------------------

  email : () -> @json.email
  salt  : () -> @json.salt
  password : () -> @json.password

#=========================================================================
