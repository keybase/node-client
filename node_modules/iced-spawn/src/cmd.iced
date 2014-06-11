{exec,spawn} = require 'child_process'
stream = require './stream'
util = require 'util'
semver = require 'semver'
fs = require 'fs'

##=======================================================================

_log = (x) -> process.stderr.write x.toString('utf8')
_engine = null
exports.set_log = set_log = (log) -> _log = log
exports.set_default_engine = (e) -> _engine = e
_quiet = null
exports.set_default_quiet = (q) -> _quiet = q

##=======================================================================

class BaseEngine

  #---------------

  constructor : ({@args, @stdin, @stdout, @stderr, @name, @opts, @log}) ->
    @stderr or= new stream.FnOutStream(@log or _log)
    @stdin or= new stream.NullInStream()
    @stdout or= new stream.NullOutStream()
    @opts or= {}
    @args or= []
    @_exit_cb = null

  #---------------

  _maybe_call_callback : () ->
    if @_exit_cb? and @_can_finish()
      cb = @_exit_cb
      @_exit_cb = null
      cb @_err, @_exit_code

  #---------------

  wait : (cb) ->
    @_exit_cb = cb
    @_maybe_call_callback()

##=======================================================================

dos_cmd_escape = (cmd) ->
  out = for c in cmd
    c = "" + c # convert all integers to strings...
    if c.match /[&<>()@^| ]/ then "^#{c}"
    else c
  out.join('')

#-----------------

dos_flatten_argv = (argv) ->
  (dos_cmd_escape a for a in argv).join ' '

##=======================================================================

exports.SpawnEngine = class SpawnEngine extends BaseEngine

  #---------------

  constructor : ({args, stdin, stdout, stderr, name, opts, log, @other_fds}) ->
    super { args, stdin, stdout, stderr, name, opts, log }

    @_exit_code = null
    @_err = null
    @_win32 = (process.platform is 'win32')
    @_closed = false
    @_configure_other_fds()

  #---------------

  # We can specify FDS other that 0,1,2 via the other_fds option;
  # we need to massage what we pass to spawn though to make this happen.
  _configure_other_fds : () ->
    if @other_fds?
      max = 0
      for k,v of @other_fds
        if k > max then max = k
      pipes = ('pipe' for [0..2])
      for i in [3..max]
        pipes.push (if @other_fds[i] then 'pipe' else null)
      @opts.stdio = pipes

  #---------------

  _spawn : () ->
    args = @args
    name = @name
    opts = @opts
    if @_win32
      cmdline = dos_flatten_argv [ name ].concat(args)
      args = [ "/s", "/c", '"' + cmdline + '"' ]
      name = "cmd.exe"
      # shallow copy to not mess with what's passed to us
      opts = util._extend({}, @opts)
      opts.windowsVerbatimArguments = true
    @proc = spawn name, args, opts

  #---------------

  _node_v0_10_workarounds : (cb) ->
    if true #unless process.stdin._handle?
      await fs.fstat 0, defer err, stat
      if err?
        await fs.open process.execPath, "r", defer err, fd
        if err?
          console.error "Workaround for stdin bug failed: #{err.message}"
        #else if fd isnt 0
        # skip the spammy warning (espcially on windows)
        # console.error "Workaround for stdin bug failed! Got #{fd} != 0"
    cb()

  #---------------

  _node_workarounds : (cb) ->
    if semver.lt(process.version, "v0.11.0")
      await @_node_v0_10_workarounds defer()
    cb()

  #---------------

  # For backwards compatibility, we should still return '@', so do the
  # real work of running in a subcall.
  run : (cb = null) ->
    @_run cb
    @ 

  #---------------

  _run : (cb) ->
    await @_node_workarounds defer()
    @_spawn()
    @stdin.pipe @proc.stdin
    @proc.stdout.pipe @stdout
    @proc.stderr.pipe @stderr

    if @other_fds?
      for k,v of @other_fds
        if v.is_readable() then v.pipe @proc.stdio[k]
        else @proc.stdio[k].pipe v

    @pid = @proc.pid
    @proc.on 'exit', (status) => @_got_exit status
    @proc.on 'error', (err)   => @_got_error err
    @proc.on 'close', (code)  => @_got_close code
    cb? null

  #---------------

  _got_close : (code) -> 
    @_closed = true
    @_maybe_call_callback()

  #---------------

  _got_exit : (status) ->
    @_exit_code = status
    @proc = null
    @pid = -1
    @_maybe_call_callback()

  #---------------

  _got_error : (err) ->
    @_err = err
    @proc = null
    @pid = -1
    @_maybe_call_callback()

  #---------------

  _can_finish : () -> (@_err? or @_exit_code?) and @_closed


##=======================================================================

exports.ExecEngine = class ExecEngine extends BaseEngine

  #---------------

  constructor : ({args, stdin, stdout, stderr, name, opts, log}) ->
    super { args, stdin, stdout, stderr, name, opts }
    @_exec_called_back = false

  #---------------

  run : () ->
    argv = [@name].concat(@args).join(" ")
    @proc = exec argv, @opts, (args...) => @_got_exec_cb args...
    @stdin.pipe @proc.stdin
    @

  #---------------

  _got_exec_cb : (err, stdout, stderr) ->
    await 
      @stdout.write stdout, defer()
      @stderr.write stderr, defer()
    @_err = err

    # Please excuse the plentiful hacks here.
    if not @_err?
      @_exit_code = 0
    else if @_err? 
      if @_err.code is 127
        @_err.errno = 'ENOENT'
      else
        @_exit_code = @_err.code
        @_err = null
        
    @_exec_called_back = true
    @_maybe_call_callback()

  #---------------

  _can_finish : () -> @_exec_called_back

##=======================================================================

exports.Engine = SpawnEngine

##=======================================================================

exports.bufferify = bufferify = (x) ->
  if not x? then null
  else if (typeof x is 'string') then new Buffer x, 'utf8'
  else if (Buffer.isBuffer x) then x
  else null

##=======================================================================

exports.run = run = (inargs, cb) ->
  {args, stdin, stdout, stderr, quiet, name, eklass, opts, engklass, log, other_fds} = inargs

  if (b = bufferify stdin)?
    stdin = new stream.BufferInStream b
  if (quiet or (_quiet? and _quiet)) and not stderr?
    stderr = new stream.NullOutStream()
  if not stdout?
    def_out = true
    stdout = new stream.BufferOutStream()
  else
    def_out = false
  err = null
  engklass or= (_engine or SpawnEngine)
  eng = new engklass { args, stdin, stdout, stderr, name, opts, log, other_fds}
  eng.run()
  await eng.wait defer err, rc
  if not err? and (rc isnt 0)
    eklass or= Error
    err = new eklass "exit code #{rc}"
    err.rc = rc
  out = if def_out then stdout.data() else null
  cb err, out

##=======================================================================
