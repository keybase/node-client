
fs = require 'fs'
log = require './log'
{constants} = require './constants'
{base58} = require './basex'
crypto = require 'crypto'
C = require 'constants'
{make_esc} = require 'iced-error'
purepack = require 'purepack'
{E} = require './err'

#==================================================================

fix_stat = (stat) ->
  for f in ["ctime", "mtime", "atime"]
    stat[f] = Math.floor(stat[f].getTime()/1000)
  stat

#==================================================================

msgpack_packed_numlen = (byt) ->
  if      byt < 0x80  then 1
  else if byt is 0xcc then 2
  else if byt is 0xcd then 3
  else if byt is 0xce then 5
  else if byt is 0xcf then 9
  else 0

##======================================================================

exports.tmp_filename = tmp_filename = (stem) ->
  ext = base58.encode crypto.rng 8
  [stem, ext].join '.'

##======================================================================

exports.Basefile = class Basefile

  #------------------------

  constructor : ({@fd}) ->
    @fd = -1 unless @fd?
    @i = 0

  #------------------------

  offset : () -> @i

  #------------------------

  close : () ->
    if @fd? >= 0
      fs.close @fd
      @fd = -1
      @i = 0

##======================================================================

exports.Stdout = class Stdout extends Basefile

  constructor : () ->
    @filename = "<stdout>"
    @pos = 0
    @stream = process.stdout

  _open : (cb) -> cb null

  close : () ->

  @open : ({}, cb) ->
    file = new Stdout()
    cb err, file

  finish : (ok, cb) ->
    cb null

  write : (block, cb) ->
    if block.offset isnt @pos
      err = new E.InvalError "Can't seek stdout"
    else
      await @stream.write block.buf, null, defer err
      @pos += block.buf.length
    cb err

##======================================================================

exports.Outfile = class Outfile extends Basefile

  #------------------------

  constructor : ({@target, @mode}) ->
    super({})
    @mode = 0o644 unless @mode?
    @tmpname = tmp_filename @target
    @renamed = false
    @buf = null
    @i = 0

  #------------------------

  @open : ({target, mode}, cb) ->
    file = if target? then new Outfile { target, mode }
    else new Stdout {}
    await file._open defer err
    file = null if err?
    cb err, file

  #------------------------

  _open : (cb) ->
    esc = make_esc cb, "Open #{@target} for writing"
    flags = (C.O_WRONLY | C.O_TRUNC | C.O_EXCL | C.O_CREAT)
    await fs.open @tmpname, flags, @mode, esc defer @fd
    await fs.realpath @tmpname, esc defer @realpath
    cb null

  #------------------------

  _rename : (cb) ->
    await fs.rename @tmpname, @target, defer err
    if err?
      log.error "Failed to rename temporary file: #{err}"
    else
      @renamed = true
    cb not err?

  #------------------------

  finish : (success, cb) ->
    @close()
    await @_rename defer() if success
    await @_cleanup defer()
    cb()

  #------------------------

  _cleanup : (cb) ->
    ok = false
    if not @renamed
      await fs.unlink @tmpname, defer err
      if err?
        log.error "failed to remove temporary file: #{err}"
        ok = false
    cb ok

  #------------------------

  write : (block, cb) ->
    ok = false
    l = block.buf.length
    b = block.buf
    o = block.offset
    await fs.write @fd, b, 0, l, o, defer err, nw
    if err?
      err = new E.BadIoError "In writing #{@tmpname}@#{o}: #{err}"
    else if nw isnt l 
      err = new E.BadIoError "Short write in #{@tmpname}: #{nw} != #{l}"
    cb err

##======================================================================

exports.Infile = class Infile extends Basefile

  constructor : ({@stat, @realpath, @filename, @fd}) ->
    super { @fd }
    @buf = null
    @eof = false

  #------------------------

  more_to_go : () -> not @eof

  #------------------------

  size : () -> 
    throw new E.InternalError "file is not opened" unless @stat
    @stat.size

  #------------------------

  read : (offset, n, cb) ->
    ret = null
    @buf = new Buffer n unless @buf?.length is n
    await fs.read @fd, @buf, 0, n, offset, defer err, br
    if err? 
      err = new E.BadIoError "#{@filename}/#{offset}-#{offset+n}: #{err}"
    else if br isnt n 
      err = new E.BadIoError "Short read: #{br} != #{n}"
    else
      ret = new Block { @buf, offset }
    cb err, ret

  #------------------------

  next : (n, cb) ->
    eof = false
    if (rem = @stat.size - @i) < n 
      n = rem
      eof = true
    await @read @i, n, defer err, block
    if block?
      @i += block.len()
    else
      eof = true
    @eof = eof
    cb err, block, eof

  #------------------------

  @open : (filename, cb) ->
    file = new Infile {filename}
    await file._open defer err
    file = null if err?
    cb err, file

  #------------------------

  finish : (ok, cb) ->
    @close()
    cb null

  #------------------------

  _open : (cb) ->
    esc = make_esc cb, "Open #{@filename}"
    flags = C.O_RDONLY
    await fs.open @filename, flags, esc defer @fd
    await fs.fstat @fd, esc defer @stat
    await fs.realpath @filename, esc defer @realpath
    cb null

#==================================================================

concat = (lst) ->
  Buffer.concat lst

##======================================================================

class Queue
  constructor : ->
    @_q = []
    @_cb = null
  push : (args...) ->
    if @_cb?
      tmp = @_cb
      @_cb = null
      tmp args...
    else
      @_q.push args
  pop : (i, cb) ->
    if @_q.length?
      trip = @_q[0]
      @_q = @q[1...]
      cb trip...
    else
      @_cb = cb

##======================================================================
