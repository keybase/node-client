
log = require './log'
{daemon} = require './util'
fs = require 'fs'
{client,init_client} = require './client'
{E} = require './err'

#=========================================================================

exports.Launcher = class Launcher 

  constructor : ({@config}) ->

  #------------------------------

  run : (cb) ->
    cli = null
    ok = true
    await @check_socket defer err

    # We can recover from a not-found error, we just need to 
    # launch a new server!
    if err? and (err instanceof E.NotFoundError)
      await @launch defer err

    if not err?
      log.debug "+> connecting to client"
      await init_client @config.sockfile(), defer err
      if err?
        log.error "Failed to initialize client: #{err}"
      else
        log.debug "-> connected!"
    if not err?
      cli = client()
      await cli.ping defer err
      if err
        log.error "Failed to ping daemon process: #{err}"
      else
        log.info "successfully pinged daemon process"
    cli = null if err?
    cb err, cli

  #------------------------------

  check_socket : (cb) ->
    f = @config.sockfile()
    await fs.stat f, defer err, stat
    if err?.code is 'ENOENT'
      err = new E.NotFoundError f
    else if not err? and not stat.isSocket()
      msg = "#{f}: socket wasn't a socket"
      err = new E.InvalError msg
    cb err

  #------------------------------

  launch : (cb) ->
    log.info "+> Launching background server"
    ch = daemon [ "server", "--daemon" ]
    await ch.once 'message', defer msg
    if msg.err?.length
      for m in msg.err
        log.error "Error launching daemon: #{m}"
      err = new E.DaemonError "failed to launch daemon"
    else
      log.info "-> Launch succeded: ok=#{msg.ok}"
    cb err

#=========================================================================
