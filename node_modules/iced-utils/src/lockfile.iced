
fs = require 'fs'
{prng} = require 'crypto'
{a_json_parse} = require './util'
{athrow,make_esc} = require 'iced-error'

#==========================================================================

_all = []

#==========================================================================

get_id = () -> prng(16).toString('hex')

#==========================================================================

read_all = (fd, cb) ->
  err = null
  eof = false
  bufs = []
  l = 0x1000
  until err? or eof
    b = new Buffer l
    await fs.read fd, b, 0, l, null, defer err, nbytes
    if err? then # noop
    else if nbytes is 0 then eof = true
    else
      b = b[0...nbytes]
      bufs.push b
  cb err, Buffer.concat(bufs)

#==========================================================================

class Lockfile

  #--------------------

  constructor : ({@filename, wait_limit, poke_timeout, reclaim_timeout, poke_interval, retry_interval, mode, @log}) ->
    @retry_interval  = retry_interval or 100                  # Retry every interval ms
    @poke_interval   = poke_interval or 100                   # poke the file every 100ms
    @poke_timeout    = poke_timeout or (@poke_interval * 20)  # after 20 missed pokes, declare failure
    @reclaim_timeout = reclaim_timeout or (@poke_interval*5)  # After 5 timeslots, we can take it
    @wait_limit      = 10*1000                                # give up the wait after 10s
    @mode            = mode or 0o644                          # prefered file mode 
    @id              = get_id()
    @_locked         = false
    @_maintain_cb    = null
    @_release_cb     = null

  #--------------------

  _log : (level, s) ->
    if @log?
      s = "#{@filename}: #{s}"
      @log[level] s

  #--------------------

  warn : (s) -> @_log 'warn', s
  info : (s) -> @_log 'info', s

  #--------------------

  _acquire_1 : (cb) ->
    res = false
    unlinked = false
    await fs.open @filename, 'wx', @mode, defer err, @fd
    if not err? then res = true
    else
      await @_acquire_1_fallback defer err, unlinked
      @warn err.message if err?
    cb res, unlinked

  #--------------------

  _lock_dat : () -> 
    s = JSON.stringify [ Date.now(), @id, process.pid ]
    new Buffer s, 'utf8'

  #--------------------

  # If we failed to acquire the lock, we now need to ask if the lock is stale
  # because its previous holder died while holding it.  We do this by:
  #   1. Checking the timestamp in the lock.
  #   2. If the timestamp is too far in the past, then we try to overwrite the lock with
  #      our process's info. Note that this operation isn't guaranteed to be atomic,
  #      and we'll have no way of knowing if we won or not.
  #   3. If our overwrite stands for a short timeout, then we can conclude that we won.
  #      Now, we're allowed to delete the file.
  _acquire_1_fallback : (cb) ->
    unlinked = false
    esc = make_esc cb, "_acquire_1_fallback"
    err = null
    await fs.open @filename, 'r', esc defer rfd
    await read_all rfd, esc defer buf
    await a_json_parse buf, esc defer jso
    now = Date.now()
    if not Array.isArray(jso) or jso.length < 2
      err = new Error "Bad lock file; expected an array with 2 values"
    else if (jso[1] is @id) and (now - jso[0] > @reclaim_timeout)
      await fs.unlink @filename, esc defer()
      unlinked = true
    else if (jso[1] isnt @id) and (now - jso[0] > @poke_timeout)
      obj = @_lock_dat() 
      await fs.writeFile @filename, obj, { encoding : 'utf8', @mode}, esc defer()
    cb null, unlinked

  #--------------------

  acquire : (cb) ->
    acquired = false
    start = Date.now()
    err = null
    loop
      await @_acquire_1 defer acquired, unlinked
      break if acquired
      break if @wait_limit and (Date.now() - start) > @wait_limit
      await setTimeout defer(), @retry_interval unless unlinked
    if acquired
      @maintain_lock_loop()
    unless acquired
      err = new Error "failed to acquire lock"
    cb err

  #--------------------

  release : (cb) ->
    if @_locked
      @_release_cb = cb
      @_locked = false
      @_maintain_cb?()
    else if cb?
      cb new Error "tried to unlock file that wasn't locked"

  #--------------------

  maintain_wait : (cb) ->
    rv = new iced.Rendezvous()
    @_maintain_cb = rv.id(true).defer()
    setTimeout rv.id(false).defer(), @poke_interval
    await rv.wait defer which
    cb()

  #--------------------

  maintain_lock_loop : () ->
    @_locked = true
    while @_locked
      b = @_lock_dat()
      await fs.write @fd, b, 0, b.length, 0, defer err
      if err?
        @warn "error in maintain_lock_loop: #{err}"
      if @_locked
        await @maintain_wait defer()
    await fs.unlink @filename, defer err
    if err?
      @warn "error deleting lock file: #{err}"
    @_release_cb? err

#==========================================================================

exports.Lockfile = Lockfile

#==========================================================================
