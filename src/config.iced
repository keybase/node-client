
path = require 'path'
fs = require 'fs'
log = require './log'
util = require 'util'
mkdirp = require 'mkdirp'
{purge} = require './util'

#=========================================================================

exports.Config = class Config

  #-------------------

  constructor : (@filename, @opts) ->
    @json = null
    @loaded = false
    @cache = {}
    @changed = false

  #-------------------

  open : (cb) ->
    err = null
    await fs.exists @filename, defer @found
    if @found
      await @load defer err
    else if not @opts.in_config
      log.warn "No config file found; tried '#{@filename}'"
      log.warn "Run 'keybase config' to make a new config file"
    cb err

  #-------------------

  is_empty : () -> not(@json?)
  is_dirty : () -> @changed

  #-------------------

  write : (cb) ->
    err = null
    if @changed
      @json = purge @json
      dat = JSON.stringify @json, null, "    "
      d = path.dirname @filename
      await mkdirp path.dirname(@filename), 0o700, defer err, n
      if err?
        log.error "Error creating directory '#{d}': #{err.message}"
      else 
        if n > 0
          log.warn "Created directory #{d}"
        await fs.writeFile @filename, dat, { mode : 0o600 }, defer err
        if err?
          log.error "Error writing to #{@filename}: #{err}"
    cb err

  #-------------------

  get : (key) ->
    parts = key.split "."
    v = @json
    (v = v[p] for p in parts when v?)
    v 

  #-------------------

  set : (key, val) ->
    parts = key.split "."
    if not @json?
      @json = {}
      @changed = true
    d = @json
    for p in parts[0...(parts.length-1)]
      unless d[p]?
        d[p] = {}
        @changed = true
      d = d[p]
    last = parts[-1...][0]
    e = d[last]
    if (e isnt val)
      d[last] = val
      @changed = true

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

#=========================================================================
