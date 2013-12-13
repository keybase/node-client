
crypto = require 'crypto'
purepack = require 'purepack'
log = require './log'
{constants} = require './constants'
stream = require 'stream'
{Queue} = require './queue'

iced.catchExceptions()

#==================================================================

pack2 = (o) ->
  b1 = purepack.pack o, 'buffer', { byte_arrays : true }
  b0 = purepack.pack b1.length, 'buffer'
  Buffer.concat [ b0, b1 ]

#==================================================================

# pad datasz bytes to be a multiple of blocksz
pkcs7_padding = (datasz, blocksz) ->
  plen = blocksz - (datasz % blocksz)
  new Buffer (plen for i in plen)

#==================================================================

bufeq = (b1, b2) ->
  return false unless b1.length is b2.length
  for b, i in b1
    return false unless b is b2[i]
  return true

#==================================================================

nibble_to_str = (n) ->
  ret = n.toString 16
  ret = "0" + ret if ret.length is 1
  ret

#==================================================================

dump_buf = (b) ->
  l = b.length
  bytes = (nibble_to_str c for c in b)
  "Buffer(#{l})<#{bytes.join ' '}>"

#==================================================================

secure_bufeq = (b1, b2) ->
  ret = true
  if b1.length isnt b2.length
    ret = false
  else
    for b, i in b1
      ret = false unless b is b2[i]
  return ret

#==================================================================

class AlgoFactory 

  constructor : ->
    # Keysize in bytes for AES256 and Blowfish
    @ENC_KEY_SIZE = 32
    @ENC_BLOCK_SIZE = 16
    # Use the same keysize for our MAC too
    @MAC_KEY_SIZE = 32
    @MAC_OUT_SIZE = 32

  total_key_size : () ->
    2 * @ENC_KEY_SIZE + @MAC_KEY_SIZE

  ciphers : () -> [ "aes-256-cbc", "camellia-256-cbc" ]

  num_ciphers : () -> @ciphers().length

  pad : (buf) ->
    padding = pkcs7_padding buf.length, @ENC_BLOCK_SIZE
    Buffer.concat [ buf, padding ]

  produce_keys : (bytes) ->
    eks = @ENC_KEY_SIZE
    mks = @MAC_KEY_SIZE
    parts = keysplit bytes, [ eks, eks, mks ]
    ret = {
      aes      : parts[0]
      camellia : parts[1]
      hmac     : parts[2]
    }
    ret

#==================================================================

gaf = new AlgoFactory()

#==================================================================

class FooterizingFilter

  #----------------

  constructor : (@filesz) ->
    @_i = 0
    @_footer_blocks = []
    @_footer_len = null

  #----------------

  filter : (block) ->
    # See Preamble --- the footer len is encoded in the first byte
    # of the file.  This is a hack that should work for all practical
    # purposes.
    @_footer_len = block[0] unless @_footer_len?

    # Bytes of the body of the file that remain.  
    bdrem = @filesz - @_i - @_footer_len
    if block.length > bdrem
      footer_part = if (bdrem > 0) then block[bdrem...] else block
      @_footer_blocks.push footer_part
      ret = if (bdrem > 0) then block[0...bdrem] else null
    else
      ret = block

    @_i += block.length
    return ret

  #----------------

  footer : () ->
    ret = Buffer.concat @_footer_blocks
    if ret.length isnt @_footer_len
      log.warn "Got wrong footer size; wanted #{@_footer_len}, but got #{ret.length}"
    ret

#==================================================================

class Preamble

  @pack : () ->
    C = constants.Preamble
    i = new Buffer 4
    i.writeUInt32BE C.FILE_VERSION, 0
    ret = Buffer.concat [ new Buffer(C.FILE_MAGIC), i ]

    # As a pseudo-hack, the first byte is the length of the footer.
    # This makes framing the file convenient.
    footer_len = pack2(new Buffer [0...(gaf.MAC_OUT_SIZE) ]).length
    ret[0] = footer_len

    ret

  @unpack : (b) -> bufeq Preamble.pack(), b
  
  @len : () -> 12

#==================================================================

msgpack_packed_numlen = (byt) ->
  if      byt < 0x80  then 1
  else if byt is 0xcc then 2
  else if byt is 0xcd then 3
  else if byt is 0xce then 5
  else if byt is 0xcf then 9
  else 0

#==================================================================

keysplit = (key, splits) ->
  ret = []
  start = 0
  for s in splits
    end = start + s
    ret.push key[start...end]
    start = end
  ret.push key[start...]
  ret

#==================================================================

class Transform extends stream.Transform

  #---------------------------

  constructor : (pipe_opts) ->
    super pipe_opts
    @_blocks = []
    @_disable_ciphers()
    @_disable_streaming()
    @_ivs = null

  #---------------------------

  _enable_ciphers   : -> @_cipher_fn = (block) => @_update_ciphers block
  _disable_ciphers  : -> @_cipher_fn = (block) => block

  #---------------------------

  _disable_streaming : ->  
    @_blocks = []
    @_sink_fn = (block) -> @_blocks.push block

  #---------------------------

  _enable_streaming  : -> 
    buf = Buffer.concat @_blocks
    @_blocks = []
    @push buf
    @_sink_fn = (block) -> @push block

  #---------------------------

  _send_to_sink : (block, cb) ->
    @_sink_fn @_process block
    cb() if cb?

  #---------------------------

  _process : (chunk)  -> @_mac @_cipher_fn chunk

  #---------------------------

  _prepare_macs : () ->
    # One mac for the header, and another for the whole file (including
    # the header MAC)
    @macs = (crypto.createHmac('sha256', @keys.hmac) for i in [0...2])

  #---------------------------

  _mac : (block) ->
    for m,i in @macs
      m.update block
    block

  #---------------------------

  _prepare_ciphers : () ->
    enc = @is_enc()
    ciphers = gaf.ciphers()
    @_ivs = (crypto.rng(gaf.ENC_BLOCK_SIZE) for i in ciphers) unless @_ivs?

    prev = null

    @ciphers = for c, i in ciphers
      key = @keys[c.split("-")[0]]
      iv = @_ivs[i]
      fn = if enc then crypto.createCipheriv else crypto.createDecipheriv
      fn c, key, iv

    # decrypt in the opposite order
    @ciphers.reverse() unless enc

  #---------------------------

  # Called before init_stream() to key our ciphers and MACs.
  setup_keys : (cb) ->
    if @key_material? 
      if (got = @key_material.length) is (wanted = gaf.total_key_size())
        km = @key_material
      else
        log.error "Key material size mismatch: #{got} != #{wanted}"
    else
      await derive_key_material @pwmgr, @is_enc(), defer km
    if km
      @keys = gaf.produce_keys km
      ok = true
    else ok = false
    cb ok

  #---------------------------

  # Chain the ciphers together, without any additional buffering from
  # pipes.  We're going to simplify this alot...
  _update_ciphers : (chunk) ->
    for c in @ciphers
      chunk = c.update chunk
    chunk

  #---------------------------
  # Cascading final update, the final from one cipher needs to be
  # run through all of the downstream ciphers...
  _final : () ->
    bufs = for c,i in @ciphers
      chunk = c.final()
      for d in @ciphers[(i+1)...]
        chunk = d.update chunk
      chunk
    Buffer.concat bufs

  #---------------------------

  init : (cb) ->
    await @setup_keys defer ok
    @init_stream() if ok
    cb ok

#==================================================================

exports.derive_key_material = derive_key_material = (pwmgr, enc, cb) ->
  tks = gaf.total_key_size()
  await pwmgr.derive_key_material tks, enc, defer km
  cb km

#==================================================================

exports.Encryptor = class Encryptor extends Transform

  constructor : ({@stat, @pwmgr}, pipe_opts) ->
    super pipe_opts
    @packed_stat = pack2 @stat, 'buffer'

  #---------------------------

  validate : () -> [ true ]
  is_enc   : () -> true
  version  : () -> constants.VERSION

  #---------------------------

  _flush_ciphers : () -> @_sink_fn @_mac @_final()

  #---------------------------

  _write_preamble : () -> @_send_to_sink Preamble.pack()
  _write_pack     : (d) -> @_send_to_sink pack2 d
  _write_header   : () -> @_write_pack @_make_header()
  _write_mac      : () -> @_write_pack @macs.pop().digest()
  _write_metadata : () -> @_send_to_sink @packed_stat

  #---------------------------

  _make_header : () ->
    out = 
      version : constants.VERSION
      ivs : @_ivs
      statsize : @packed_stat.length
      filesize : @stat.size
    return out

  #---------------------------

  _flush : (cb) ->
    @_flush_ciphers()
    @_disable_ciphers()
    @_write_mac()
    cb()

  #---------------------------

  init_stream : () ->

    @_prepare_ciphers()
    @_prepare_macs()

    @_write_preamble()
    @_write_header()
    @_write_mac()

    # Finally, we're starting to encrypt...
    @_enable_ciphers()
    @_write_metadata()

    # Now, we're all set, and subsequent operations are going
    # to stream to the output....
    @_enable_streaming()

  #---------------------------

  _transform : (block, encoding, cb) -> 
    @_send_to_sink block, cb

#==================================================================

[HEADER, BODY, FOOTER] = [0..2]

#==================================================================

exports.Decryptor = class Decryptor extends Transform

  constructor : ({@pwmgr, @stat, @total_size, @key_material}, pipe_opts) ->
    super pipe_opts
    @_section = HEADER
    @_n = 0  # number of body bytes reads
    @_q = new Queue
    @_enable_clear_queuing()

    @total_size = @stat.size if @stat? and not @total_size?
    if not @total_size?
      throw new Error "cannot find filesize"

    @_ff = new FooterizingFilter @total_size

  #---------------------------

  is_enc : () -> false

  #---------------------------

  _enable_clear_queuing : ->
    @_enqueue = (block) => 
      @_q.push block
    @_dequeue = (n, cb) => 
      await @_q.read n, defer b
      @_mac b if b?
      cb b

  #---------------------------

  _enable_deciphered_queueing : ->
    @_enqueue = (block) ->
      if block?
        @_mac block
        out = @_update_ciphers block
        @_q.push out
    @_dequeue = (n, cb) => @_q.read n, cb

  #---------------------------

  _disable_queueing : ->
    @_enqueue = null
    @_dequeue = null

  #---------------------------

  _read_preamble : (cb) ->
    await @_dequeue Preamble.len(), defer b
    ok = Preamble.unpack b 
    log.error "Failed to unpack preamble: #{b.inspect()}" unless ok
    cb ok

  #---------------------------

  _read_unpack : (cb) ->
    await @_dequeue 1, defer b0
    framelen = msgpack_packed_numlen b0[0]
    if framelen is 0
      log.error "Bad msgpack len header: #{b.inspect()}"
    else

      if framelen > 1
        # Read the rest out...
        await @_dequeue (framelen-1), defer b1
        b = Buffer.concat [b0, b1]
      else
        b = b0

      # We've read the framing in two parts -- the first byte
      # and then the rest
      [err, frame] = purepack.unpack b

      if err?
        log.error "In reading msgpack frame: #{err}"
      else if not (typeof(frame) is 'number')
        log.error "Expected frame as a number: got #{frame}"
      else 
        await @_dequeue frame, defer b
        [err, out] = purepack.unpack b
        log.error "In unpacking #{b.inspect()}: #{err}" if err?
    cb out

  #---------------------------

  _read_header : (cb) ->
    ok = false
    await @_read_unpack defer @hdr
    if not @hdr?
      log.error "Failed to read header"
    else if @hdr.version isnt constants.VERSION
      log.error "Only know version #{constants.VERSION}; got #{@hdr.version}"
    else if not (@_ivs = @hdr.ivs)? or (@_ivs.length isnt gaf.num_ciphers())
      log.error "Malformed headers; didn't find #{gaf.num_ciphers()} IVs"
    else
      ok = true
    cb ok

  #---------------------------

  _check_mac : (cb) ->
    wanted = @macs.pop().digest()
    await @_read_unpack defer given
    ok = false
    if not given?
      log.error "Couldn't read MAC from file"
    else if not secure_bufeq given, wanted
      log.error "Header MAC mismatch error"
    else
      ok = true
    cb ok

  #---------------------------

  _enable_queued_ciphertext : () => 
    buf = @_q.flush()
    @_enable_deciphered_queueing()
    @_enqueue buf

  #---------------------------

  init_stream : () ->
    ok = true
    @_prepare_macs()

    # Set this up to fly in the background...
    @_read_headers()

  #---------------------------

  _read_headers : (cb) ->

    await @_read_preamble defer ok
    await @_read_header   defer ok if ok

    # can only prepare the ciphers after we've read the header
    # (since the header has the IV!)
    @_prepare_ciphers()

    await @_check_mac     defer ok if ok

    @_enable_queued_ciphertext()   if ok
    await @_read_metadata defer ok if ok 

    @_start_body()                 if ok

    cb?()

  #---------------------------

  validate : () -> 
    if @_final_mac_ok then [ true, null ]
    else [ false, "Full-file MAC failed" ]

  #---------------------------

  _flush : (cb)->

    # First flush the decryption pipeline and write any
    # new blocks out to the output stream
    block = @_final()
    @push block if block? and block.length

    # Now change over the clear block queuing. 
    @_enable_clear_queuing()

    # The footer is in the FooterizingFilter, which kept the
    # last N bytes of the stream...
    @_enqueue @_ff.footer()

    # Finally, we can check the mac and hope that it works...
    await @_check_mac defer @_final_mac_ok

    cb()

  #---------------------------

  _stream_body : (block, cb) ->
    @push bl if (bl = @_update_ciphers @_mac block)?
    cb?() 

  #---------------------------

  _start_body : () ->
    @_section = BODY
    buf = @_q.flush()
    @_disable_queueing()
    @push buf

  #---------------------------

  _read_metadata : (cb) ->
    await @_read_unpack defer @_metadata
    cb !!@_metadata

  #---------------------------

  _transform : (block, encoding, cb) ->
    block = @_ff.filter block
    if not block? or not block.length then null
    else if @_enqueue? then @_enqueue block
    else await @_stream_body block, defer()
    cb()

#==================================================================
