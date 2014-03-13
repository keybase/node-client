
fs = require 'fs'
log = require './log'
util = require 'util'
{purge} = require './util'
{mkdirp} = require './fs'
{constants} = require './constants'

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
    log.debug "+ opening config file: #{@filename}"
    await fs.exists @filename, defer @found
    if @found
      await @load defer err
    else if not @opts.quiet
      log.warn "No config file found; tried '#{@filename}'"
    log.debug "- opened config file; found=#{@found}"
    cb err

  #-------------------

  is_empty : () -> not(@json?)
  is_dirty : () -> @changed

  #-------------------

  unlink : (cb) ->
    await fs.unlink @filename, defer err
    log.info "Removing file: #{@filename}"
    cb err

  #-------------------

  write : (cb) ->
    err = null
    if @changed
      @json = purge @json
      dat = JSON.stringify @json, null, "    "
      await mkdirp @filename, defer err, d
      if err?
        log.error "Error creating directory '#{d}': #{err.message}"
      else 
        await fs.writeFile @filename, dat, { mode : constants.permissions.file }, defer err
        if err?
          log.error "Error writing to #{@filename}: #{err}"
      unless err?
        log.info "Updated file: #{@filename}"
        @changed = false
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
    log.debug "+ loading config file #{@filename}"
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

    msg = if @opts.secret then "<redacted>" else JSON.stringify @json
    log.debug "- loaded config file -> #{msg}"
    cb err

  #-------------------

  obj : () -> @json
  clear : () -> @json = {}

#=========================================================================
