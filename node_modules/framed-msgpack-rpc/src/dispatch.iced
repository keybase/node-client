
{Packetizer} = require './packetizer'
dbg = require './debug'

iced = require('./iced').runtime

##=======================================================================

exports.Reponse = class Reponse
  constructor : (@dispatch, @seqid) ->
    @debug_msg = null
    
  result : (res) ->
    @debug_msg.response(null, res).call() if @debug_msg
    @dispatch.respond @seqid, null, res

  error : (err) ->
    @debug_msg.response(err, null).call() if @debug_msg
    @dispatch.respond @seqid, err, null

##=======================================================================

exports.Dispatch = class Dispatch extends Packetizer

  INVOKE : 0
  RESPONSE : 1
  NOTIFY   : 2

  ##-----------------------------------------

  constructor : () ->
    @_invocations = {}
    @_handlers = {}
    @_seqid = 1
    @_dbgr = null
    super

  ##-----------------------------------------

  set_debugger : (d) -> @_dbgr = d
 
  ##-----------------------------------------

  _dispatch : (msg) ->

    # We can escape from this, but it's not great...
    if not msg instanceof Array or msg.length < 2
      @_warn "Bad input packet in dispatch"
    else
      switch (type = msg.shift())
        when @INVOKE
          [seqid,method,param] = msg
          response = new Reponse @, seqid
          @_serve { method, param, response }
        when @NOTIFY
          [method,param] = msg
          @_serve { method, param }
        when @RESPONSE
          [seqid,error,result] = msg
          @_dispatch_handle_response { seqid, error, result }
        else
          @_warn "Unknown message type: #{type}"

  ##-----------------------------------------

  _dispatch_handle_response : ({seqid, error, result}) ->
    @_call_cb { seqid, error, result }
    
  ##-----------------------------------------
  
  _call_cb : ({seqid, error, result}) ->
    cb = @_invocations[seqid]
    if cb
      delete @_invocations[seqid]
      cb error, result
   
  ##-----------------------------------------

  cancel : (seqid) -> @_call_cb { seqid, error : "cancelled", result : null } 
 
  ##-----------------------------------------

  _next_seqid : () ->
    ret = @_seqid
    @_seqid++
    return ret

  ##-----------------------------------------
  
  make_method : (prog, meth) ->
    if prog then [ prog, meth ].join "." else meth
 
  ##-----------------------------------------

  respond : (seqid, error, result) ->
    msg = [ @RESPONSE, seqid, error, result ]
    @send msg
   
  ##-----------------------------------------

  invoke : ({program, method, args, notify}, cb, out) ->

    method = @make_method program, method
    
    seqid = @_next_seqid()
    
    if notify
      type = @NOTIFY
      dtype = dbg.constants.type.CLIENT_NOTIFY
    else
      type = @INVOKE
      dtype = dbg.constants.type.CLIENT_INVOKE
      
    msg = [ type, seqid, method, args ]

    if @_dbgr
      debug_msg = @_dbgr.new_message {
        method,
        seqid,
        arg : args,
        dir : dbg.constants.dir.OUTGOING,
        remote : @remote_address(),
        port : @remote_port(),
        type : dtype
      }
      debug_msg.call()
        
    
    # Down to the packetizer, which will jump back up to the Transport!
    @send msg

    if cb? or not notify

      if out?
        out.cancel = () => @cancel seqid
        
      await (@_invocations[seqid] = defer(error,result) )

      debug_msg.response(error, result).call() if debug_msg
        
    cb error, result if cb

  ##-----------------------------------------

  _dispatch_reset : () ->
    inv = @_invocations
    @_invocations = {}
    for key,cb of inv
      cb "EOF from server", {}
   
  ##-----------------------------------------

  _serve : ({method, param, response}) ->

    pair = @get_handler_pair method

    if @_dbgr
      debug_msg = @_dbgr.new_message {
        method
        seqid : response.seqid
        arg : param
        dir : dbg.constants.dir.INCOMING
        remote : @remote_address()
        port : @remote_port()
        type : dbg.constants.type.SERVER
        error : if pair then null else "unknown method"
      }

      response.debug_msg = debug_msg if response
      debug_msg.call()

    if pair then pair[1].call pair[0], param, response, @
    else if response? then response.error "unknown method: #{method}"
      
  ##-----------------------------------------

  # please override me!
  get_handler_this : (m) -> @

  # please override me!
  get_handler_pair : (m) ->
    h = @_handlers[m]
    if h then [ @get_handler_this(m), h ]
    else null

  add_handler : (method, hook, program = null) ->
    method = @make_method program, method
    @_handlers[method] = hook

  add_program : (program, hooks) ->
    for method,hook of hooks
      @add_handler method, hook, program

  add_programs : (programs) ->
    for program, hooks of programs
      @add_program program, hooks

  #
  ##-----------------------------------------
