
fs = require 'fs'
log = require './log'
C = require 'constants'
{base58} = require './basex'
crypto = require 'crypto'
path = require 'path'
{mkdir_p} = require('iced-utils').fs
{constants} = require './constants'

##======================================================================

exports.File = class File

  constructor : ({@stream, @stat, @realpath, @filename, @fd}) ->

  close : () -> @stream?.close()

##======================================================================

exports.open = open = ({filename, write, mode, bufferSize}, cb) ->
  mode or= 0o640
  bufferSize or= 1024*1024
  stat = null
  err = null
 
  flags = if write then (C.O_WRONLY | C.O_TRUNC | C.O_EXCL | C.O_CREAT)
  else C.O_RDONLY

  unless write
    await fs.stat filename, defer err, stat
    if err?
      log.warn "Failed to access file #{filename}: #{err}"
  unless err?
    ret = null
    await fs.open filename, flags, mode, defer err, fd
  unless err?
    await fs.realpath filename, defer err, realpath
    if err?
      log.warn "Realpath failed on file #{filename}: #{err}"
  unless err?
    opts = { fd, bufferSize }
    f = if write then fs.createWriteStream else fs.createReadStream
    stream = f filename, opts

  file = if err? then null
  else new File { stream , stat, realpath, filename, fd }

  cb err, file

##======================================================================

exports.tmp_filename = tmp_filename = (stem) ->
  ext = base58.encode crypto.rng 8
  [stem, ext].join '.'

##======================================================================

exports.strip_extension = strip_extension = (fn, ext) -> 
  v = fn.split "."
  l = v.length
  if v[l-1] is ext then v[0...(l-1)].join '.'
  else null

##======================================================================

exports.stdout = () -> new File {
  stream : process.stdout
  filename : "<stdout>"
  realpath : "<stdout>"
  fd : -1
}

##======================================================================

exports.Tmp = class Tmp 

  constructor : ({@target, @mode, @bufferSize}) ->
    @tmpname = tmp_filename @target
    @renamed = false

  open : (cb) ->
    await open { filename : @tmpname, write : true, @mode, @bufferSize }, defer err, @tmp
    if err?
      log.error "Error opening file: #{err}"
    cb not err?

  close : () -> @tmp?.close()

  rename : (cb) ->
    await fs.rename @tmpname, @target, defer err
    if err?
      log.error "Failed to rename temporary file: #{err}"
    else
      @renamed = true
    cb not err?

  finish : (cb) ->
    await @rename defer()
    await @cleanup defer()
    cb()

  cleanup : (cb) ->
    ok = false
    if not @renamed
      await fs.unlink @tmpname, defer err
      if err?
        log.error "failed to remove temporary file: #{err}"
        ok = false
    cb ok

  stream : () -> @tmp?.stream

##======================================================================

exports.mkdirp = (fn, cb) ->
  d = path.dirname fn
  n = 0
  err = null
  await fs.exists d, defer found
  unless found
    await mkdir_p d, constants.permissions.dir, defer err, n
    if not err? and n > 0
      log.info "Made directory '#{d}'"
  cb err, d, n

##======================================================================

