fs = require 'fs'
log = require './log'

#=========================================================================

exports.ExitHandler = class ExitHandler

  constructor : ({@config}) ->
    @_ran_hook = false
    @setup()
    @_cb = null

  hook : (cb) ->
    if not @_ran_hook 
      @_ran_hook = true
      await 
        for f in [ @config.sockfile(), @config.pidfile() ]
          log.info "unlink #{f}"
          fs.unlink f, defer()
    cb()

  on_exit : (cb) ->
    log.info "[pid #{process.pid}] shutting down...."
    await @hook defer()
    cb?()
    @_cb?()

  call_on_exit : (c) -> @_cb = c

  do_exit : (rc) ->
    await @on_exit defer()
    process.exit rc

  setup : () ->
    process.once 'exit', () => @on_exit()
    process.once 'SIGINT', () => @do_exit -1 
    process.once 'SIGTERM', () => @do_exit -2


#=========================================================================
