
{spawn, exec} = require 'child_process'

##-----------------------------------------------------------------------

exports.Child = class Child

  #-----------------------------------------

  constructor : (@args, @opts) ->
    @_startup = null
    @_exit_cb = null
    @_exit_code = null
    @_filter = null
    @_n_exits = 0

  #-----------------------------------------

  _got_data : (buffer, which) ->
    s = buffer.toString()
    process[which].write s unless @opts?.quiet

    # Maybe the parent process asked to filter stdout or stderr
    @_filter? s, which
    
    if @_startup?.check_fn s, which
      cb = @_startup.cb
      cb true
      @_startup = null

  #-----------------------------------------

  filter : (f) ->
    @_filter = f
    @
    
  #-----------------------------------------

  run : () ->
    interp = @opts.interp or 'iced'
    @proc = spawn interp, @args
    @_n_exits = 3
    @proc.stderr.on 'data', (buffer) => @_got_data buffer, 'stderr'
    @proc.stdout.on 'data', (buffer) => @_got_data buffer, 'stdout'
    @proc.stderr.on 'end', () => @_got_exit()
    @proc.stdout.on 'end', () => @_got_exit()
    @proc.on 'exit', (status) => @_got_exit status
    @pid = @proc.pid
    @

  #-----------------------------------------

  kill : (sig) -> @proc.kill sig
   
  #-----------------------------------------

  startup_check : (check_fn, cb) ->
    @_startup = { check_fn, cb }
    @

  #-----------------------------------------

  toString : () ->
    "'#{JSON.stringify @args}'" + (if @pid? then " (pid=#{@pid})" else "")
   
  #-----------------------------------------

  _do_restart : (status) ->
    d = opts?.restart?.delay or 5
    opts?.logfn? "process #{@toString()} died w/ status=#{status}; restart in #{d}s"
    await setTimeout defer(), d*1000
    @run()
   
  #-----------------------------------------

  _got_exit : (status) ->
    if status?
      @_exit_code = status
      @proc = null
      if @_startup?
        cb = @_startup.cb
        cb false
        @_startup = null
      @pid = -1
    if --@_n_exits is 0 
      if (ecb = @_exit_cb)
        @_exit_cb = null
        ecb @_exit_code 
      if opts?.restart?
        @_do_restart status
      
  #-----------------------------------------

  wait : (cb) ->
    if @_exit_code and @_n_exits is 0
      cb @_exit_code
    else
      @_exit_cb = cb

##-----------------------------------------------------------------------

exports.spawn = (args, cb, opts = {}) ->
  await (new Child args, opts).run().wait defer status
  cb status

##-----------------------------------------------------------------------
