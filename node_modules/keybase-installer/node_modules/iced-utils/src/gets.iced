
# Sample usage:
#
#  gets = (new Gets process.stdin).run()
#  
#  loop
#    await gets.gets defer err, line
#    break unless line?
#    console.log line
#
#=======================================================================================

exports.Gets = class Gets

  #------------------------

  constructor : (@_stream, opts = {}) ->
    @_lines = []
    @_curr = []
    @_n = 0
    @_hiwat = opts?.hiwat or 0x1000
    @_lowat = opts?.lowat or 0x800
    @_include_newline = !!opts?.include_newline
    @_eof = false
    @_err = null
    @_cbs = []

  #------------------------

  run : () ->
    @_stream.resume()
    @_stream.on 'data', @_buffer_data.bind(@)
    @_stream.on 'end', @_got_eof.bind(@)
    @_stream.on 'err', @_got_err.bind(@)
    @

  #------------------------

  _got_eof : () ->
    @_eof = true
    @_poke()

  #------------------------

  _got_err : (e) ->
    @_err = e
    @_poke()

  #------------------------

  _maybe_pause : () ->
    if @_n >= @_hiwat
      @_paused = true
      @_stream.pause()

  #------------------------

  _maybe_resume : () ->
    if @_paused and @_n <= @_lowat
      @_paused = false
      @_stream.resume()

  #------------------------

  _buffer_data : (dat) ->
    dat = dat.toString 'utf8'
    while (i = dat.indexOf '\n') >= 0
      end = i
      rest = dat[(i+1)...]
      i++ if @_include_newline
      @_n += i
      @_curr.push dat[0...i]
      @_lines.push @_curr.join('')
      @_curr = []
      i++ unless @_include_newline
      dat = rest
      @_poke()
    @_maybe_pause()

  #------------------------

  gets : (cb) ->
    @_cbs.push cb
    @_poke()

  #------------------------

  _poke : () -> 
    while @_lines.length and @_cbs.length
      cb = @_cbs.shift()
      line = @_lines.shift()
      @_n -= line.length
      @_maybe_resume()
      cb null, line
    while @_cbs.length and @_err?
      cb = @_cbs.shift()
      cb @_err
    while @_cbs.length and @_eof
      cb = @_cbs.shift()
      cb null, null

#=======================================================================================
