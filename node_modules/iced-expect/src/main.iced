{spawn} = require 'child_process'
{List} = require 'iced-data-structures'
util = require 'util'

#============================================================

exports.Engine = class Engine

  #-----------------------------

  constructor : ({@args, @name, opts}) ->
    @_exit_code = null
    @_exit_cb = null
    @_n_out = 0
    @_opts = opts or {}
    @_probes = new List
    @_data_buffers = { stderr : [], stdout : [] }
    @_started = false

  #-----------------------------

  collect : (which) ->
    out = Buffer.concat @_data_buffers[which]
    @_data_buffers[which] = []
    return out

  #-----------------------------

  stdout : () -> @collect 'stdout'
  stderr : () -> @collect 'stderr'

  #-----------------------------

  _got_data : (data, source) ->
    @_data_buffers[source].push data
    s = data.toString('utf8')
    if @_opts?.debug?[source]?
      console.error "Got data on #{source} >>>>>"
      console.error s
      console.error "<<<<<"
    if @_opts?.passthrough?[source]?
      process[source].write data, 'utf8'
    @_probes.walk (o) =>
      if (o.source is source) and s.match(o.pattern)
        @_probes.remove o unless o.repeat
        out_data = @collect source
        o.cb null, out_data, source
        false
      else 
        true

  #-----------------------------

  _clear_probes : () ->
    @_probes.walk (o) =>
      @_probes.remove o
      o.cb new Error "EOF before expectation met" unless o.repeat

  #-----------------------------

  expect : ({source, pattern, repeat}, cb) ->
    @_start_pipes()
    source = 'stdout' unless source?
    @_probes.push { source, pattern, repeat, cb }
    @

  #-----------------------------

  run : () ->
    @proc = spawn @name, @args
    @pid = @proc.pid
    @_n_out = 3 # we need 3 exit events before we can exit
    @

  #-----------------------------

  _start_pipes : () ->
    return if @_started
    @_started = true
    @proc.on 'exit', (status) => @_got_exit status
    @proc.stderr.on 'end',  ()     => @_maybe_finish()
    @proc.stdout.on 'end',  ()     => @_maybe_finish()
    @proc.stderr.on 'data', (data) => @_got_data data, 'stderr'
    @proc.stdout.on 'data', (data) => @_got_data data, 'stdout'

  #-----------------------------

  sendline : (args...) ->
    args[0] += "\n" if args[0][-1...][0] isnt "\n"
    @send args...

  #-----------------------------

  send : (args...) ->
    @_start_pipes()
    if @proc 
      @proc.stdin.write args...
    else
      args[-1...][0] new Error "EOF on input; can't send"

  #-----------------------------

  _got_exit : (status) ->
    @_exit_code = status
    @proc = null
    @_maybe_finish()

  #-----------------------------

  _maybe_finish : () ->
    if --@_n_out <= 0
      @_clear_probes()
      if (ecb = @_exit_cb)?
        @_exit_cb = null
        ecb @_exit_code
      @pid = -1

  #-----------------------------

  conversation : (list, cb) ->
    err = null
    for item,i in list 
      await @_do_obj item, "item #{i}", defer err
      if err? then break
    cb err

  #-----------------------------

  _do_obj : (obj, what, cb) ->
    err = null
    if typeof(obj) isnt 'object'
      err = new Error "#{what} wasn't a dictionary as expected"
    else if Object.keys(obj).length isnt 1
      err = new Error "Expected only one kv-pair per item; got otherwise in #{what}"
    else 
      k = Object.keys(obj)[0]
      v = obj[k]
      switch k
        when 'expect'
          if (typeof(v) is 'string') or (typeof(v) is 'object' and util.isRegExp(v))
            arg = { pattern : v }
          else if typeof(v) isnt 'object'
            err = new Error "Bad argument to 'expect' in #{what}"
          else
            arg = v
          unless err?
            await @expect arg, defer err
        when 'send', 'sendline'
          if typeof(v) is 'string'
            await @[k] v, defer err
          else
            err = new Error "Bad argument to #{k}: need a string in #{what}"
        else
          err = new Error "Unknown command: #{k}"
    cb err

  #-----------------------------

  wait : (cb) ->
    @_start_pipes()
    if (@_exit_code? and @_n_out <= 0) then cb @_exit_code
    else @_exit_cb = cb

#============================================================

