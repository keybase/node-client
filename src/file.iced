
fs = require 'fs'
blockcrypt  = require './blockcrypt'
log = require './log'
{constants} = require './constants'
base58 = require './base58'
crypto = require 'crypto'
C = require 'constants'
{make_esc} = require 'iced-error'
purepack = require 'purepack'
{E} = require './err'

#==================================================================

{bufeq,secure_bufeq} = blockcrypt

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

exports.Block = class Block

  constructor : ({@buf, @offset}) ->

  len : () -> if @buf then @buf.length else 0

  encrypt : (eng) -> [null, new Block { buf : eng.encrypt(@buf), @offset } ]

  decrypt : (eng) ->
    [err, buf] = eng.decrypt @buf
    out = if err? then null else new Block { buf, @offset }
    [ err , out ]

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

#==================================================================

pack2 = (o) ->
  b1 = purepack.pack o, 'buffer', { byte_arrays : true }
  b0 = purepack.pack b1.length, 'buffer'
  concat [ b0, b1 ]

##======================================================================

unpack2 = (rfn, cb) ->
  esc = make_esc cb, "unpack"
  out = null
  err = null

  await rfn 1, esc defer b0
  framelen = msgpack_packed_numlen b0[0]

  if framelen is 0
    err = new E.MsgpackError "Bad msgpack len header: #{b0.inspect()}"
  else

    if framelen > 1
      # Read the rest out...
      await rfn (framelen-1), esc defer b1
      b = concat [b0, b1]
    else
      b = b0

    # We've read the framing in two parts -- the first byte
    # and then the rest
    [err, frame] = purepack.unpack b

    if err?
      err = new E.MsgpackError "In reading msgpack frame: #{err}"
    else if not (typeof(frame) is 'number')
      err = new E.MsgpackError "Expected frame as a number: got #{frame}"
    else 
      await rfn frame, esc defer b
      [err, out] = purepack.unpack b
      err = new E.MsgpackError "In unpacking #{b.inspect()}: #{err}" if err?

  cb err, out

##======================================================================

unpack2_from_buffer = (buf, cb) ->
  rfn = (n, cb) ->
    if n > buf.length 
      err = new E.MsgpackError "read out of bounds"
      ret = null
    else 
      ret = buf[0...n]
      buf = buf[n...]
    cb err, ret
  await unpack2 rfn, defer err, buf
  cb err, buf

##======================================================================

uint32 = (i) ->
  b = new Buffer 4
  b.writeUInt32BE i, 0
  b

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

class CoderBase

  #--------------

  constructor : ({@keys, @infile, @outfile, @blocksize}) ->
    @blocksize = 1024*1024 unless @blocksize?
    @eof = false
    @opos = 0
    if (@infile instanceof CoderBase)
      @q = []

  #-------------------------

  more_to_go : () -> @infile.more_to_go()

  #--------------

  @preamble : () ->
    H = constants.Header
    concat [
      new Buffer H.FILE_MAGIC
      uint32 H.FILE_VERSION
    ]

  #--------------

  run : (cb) ->
    esc = make_esc cb, "CoderBase::run"
    await @first_block esc defer()
    bs = @sizer @blocksize
    while @more_to_go()
      await @read bs, esc defer block
      if block?
        block.offset = @opos
        await @write block, esc defer()
        @opos += block.len()
    cb null

  #--------------

  write : (buf, cb) -> 
    await @outfile.write buf, defer err
    if err?
      log.error err
    cb err

  #--------------

  # Engines can also act as infiles, so they can be chained
  next : (i, cb) ->
    await @q.pop i, defer err, iblock, 
    cb 

  #--------------

  read : (i, cb) ->
    await @infile.next i, defer err, iblock, file_eof
    if err?
      log.error err
    else if iblock?
      [err, oblock] = @filt iblock 
    if @q?
      @q.push err, oblock, file_eof
    cb err, oblock

##======================================================================

exports.Decoder = class Decoder extends CoderBase

  #--------------

  constructor : (d) ->
    super d

  #---------------------------

  _read_preamble : (cb) ->
    p = CoderBase.preamble()
    await @infile.next p.length, defer err, raw

    err = if err? then err
    else if not bufeq raw.buf, p then new E.BadPreambleError()
    else null
    cb err

  #---------------------------

  _read_unpack : (cb) ->
    rfn = (i, cb) => 
      await @infile.next i, defer err, block
      buf = block.buf unless err?
      cb err, buf
    await unpack2 rfn, defer err, obj
    cb err, obj

  #---------------------------

  _read_metadata : (cb) ->
    await @_read_unpack defer err, @hdr
    unless err?
      fields = [ "statsize", "filesize", "encrypt", "blocksize" ]
      missing = []
      for f in fields 
        missing.push f if not @hdr[f]?
      if missing.length
        err = new E.BadHeaderError "malformed header; missing #{JSON.stringify missing}"
    cb err

  #---------------------------

  _read_encrypted_stat : (cb) ->
    esc = make_esc cb, "Decode:_read_encrypted_stat"
    await @infile.next @hdr.statsize, esc defer raw
    [err, block] = @filt raw
    unless err?
      await unpack2_from_buffer block.buf, esc defer @stat 
    cb err

  #---------------------------

  _read_header : (cb) ->
    esc = make_esc cb, "Decoder::_read_header"
    await @_read_preamble esc defer()
    await @_read_metadata esc defer()
    await @_read_encrypted_stat esc defer()
    cb null

  #--------------

  _read_first_block : (cb) ->
    esc = make_esc cb, "Decoder::_read_first_block"
    @blocksize = @hdr.blocksize
    rem_off = @infile.offset()
    err = null
    if rem_off > @blocksize 
      err = new E.BadHeaderError "header was too big! #{rem_off} > #{@blocksize}"
    else
      rem_size = @blocksize - rem_off
      await @infile.next rem_size, esc defer block
      [err, block] = @filt block unless err?
      unless err?
        block.offset = 0
        await @write block, esc defer err
        @opos = block.len()
    cb err

  #--------------

  first_block : (cb) ->
    await @_read_header defer err
    if err? and (err instanceof E.BadMacError)
      err = new E.BadPwOrMacError() 
    await @_read_first_block defer err unless err?
    cb err

##======================================================================

exports.Encoder = class Encoder extends CoderBase

  #--------------

  constructor : (d) ->
    super d

  #--------------
  
  metadata : (statsize, filesize) ->
    encrypt = @encflag()
    pack2 { statsize, filesize, encrypt, @blocksize }

  #--------------
  
  header : () ->
    [_, estat ] = @filt new Block { buf : pack2(fix_stat @infile.stat), offset : -1 }
    concat [
      CoderBase.preamble()
      @metadata estat.len(), @infile.stat.size
      estat.buf
    ]

  #--------------
  
  first_block : (cb) ->
    err = null
    hdr = @header()
    if hdr.length > @blocksize
      err = new E.InvalError "First block is too big!! #{hdr.length} > #{@blocksize}"
      log.error err
    else
      rem_osize = @blocksize - hdr.length
      rem_isize = @sizer rem_osize
      await @read rem_isize, defer err, rem_block
    unless err?
      buf = concat [ hdr, rem_block.buf ]
      block = new Block { buf, offset : 0 }
      await @write block, defer err
      @opos = block.len()
    cb err

##======================================================================

exports.PlainEncoder = class PlainEncoder extends Encoder

  constructor : ({@infile, @outfile, @blocksize}) ->
    super()

  filt : (x) -> [ null, x ]
  sizer : (x) -> x
  encflag : -> 0

##======================================================================

exports.Encryptor = class Encryptor extends Encoder

  constructor : (d) -> 
    super d
    # super(d) should set @keys
    @block_engine = new blockcrypt.Engine @keys

  filt : (x) -> x.encrypt(@block_engine) 
  sizer  : (x) -> blockcrypt.Engine.input_size x
  encflag : -> 1

##======================================================================

exports.Decryptor = class Decryptor extends Decoder

  constructor : (d) ->
    super d
    @block_engine = new blockcrypt.Engine @keys

  filt   : (x) -> x.decrypt(@block_engine)
  sizer  : (x) -> x

##======================================================================

exports.PlainDecoder = class Decryptor extends Decoder

  constructor : ({infile, @outfile}) ->
    super()
  filt   : (x) -> [ null, x ]
  sizer  : (x) -> x

##======================================================================
