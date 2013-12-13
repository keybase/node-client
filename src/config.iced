
path = require 'path'
fs = require 'fs'
log = require './log'
util = require 'util'
mkdirp = require 'mkdirp'

#=========================================================================

exports.Config = class Config

  #-------------------

  constructor : () ->
    @json = null
    @loaded = false
    @cache = {}

  #-------------------

  init : (fn) ->
    @filename = if fn? then fn
    else if (f = process.env.MKB_CONFIG)? then f
    else path.join process.env.HOME, ".mkb.conf"

  #-------------------

  find : (file, cb) ->
    @init file
    await fs.exists @filename, defer @found
    cb @found

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
    ok = true
    
    await fs.readFile @filename, defer err, file
    if err?
      log.error "Cannot read file #{@filename}: #{err}"
      ok = false

    if ok
      try
        @json = JSON.parse file
      catch e
        log.error "Invalid json in #{@filename}: #{e}"
        ok = false

    if ok 
      for key in [ 'aws', 'vault' ]
        unless @json?[key]?
          log.error "Missing JSON component '#{key}' in #{@filename}" unless @json?[key]?
          ok = false

    log.warn "Failed to load config" unless ok

    cb ok

  #-------------------

  tmpdir : () ->
    @_tmpdir = @config?.json?.files?.dir or (path.join path.sep, "tmp", "mkb") unless @_tmpdir?
    @_tmpdir

  #-------------------

  _get_file : (which) -> 
    unless (f = @cache[which])?
      f = @config?.json?.files?[which] or path.join(@tmpdir(), "mkb.#{which}") 
      @cache[which] = f
    f

  #-------------------

  sockfile : () -> @_get_file "sock"
  pidfile  : () -> @_get_file "pid"
  logfile  : () -> @_get_file "log"

  #-------------------

  pidfile : (cb) ->
    @_pidfile = @config?.json?.files?.pid or (path.join @tmpdir(), "mkb.pid") unless @_pidfile?
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
    @json.file_extension or "mke"

  #-------------------

  aws   : () -> @json.aws
  arns  : () -> @json.arns
  vault : () -> @json.vault
  email : () -> @json.email
  salt  : () -> @json.salt
  password : () -> @json.password
  sns   : () -> @json.arns.sns
  sqs   : () -> @json.arns.sqs

#=========================================================================
