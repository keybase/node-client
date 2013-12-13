
{Base} = require './base'
{add_option_dict} = require './argparse'
log = require '../log'
{Server} = require '../server'
{daemon} = require '../util'
fs = require 'fs'

#=========================================================================

exports.Command = class Command extends Base

  constructor : (args...) ->
    super args...
    @_e = []

  #------------------------------

  err : (m) ->
    log.error m
    @_e.push m

  #------------------------------

  OPTS : 
    q :
      alias : 'daemon'
      action : 'storeTrue'
      help : 'work in background mode, logging to a file'

  #------------------------------

  add_subcommand_parser : (scp) ->
    opts = 
      help : 'run in daemon mode to coordinate downloads'
    name = 'server'
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ]

  #------------------------------

  listen : (cb) ->
    await @config.make_tmpdir defer ok
    if ok
      sf = @config.sockfile()
      @server = new Server { cmd : @ }
      await @server.listen defer err
      if err?
        @err "Error listening on #{sf}: #{err}"
        ok = false
    cb ok

  #------------------------------

  daemonize : (cb) ->
    ok = true
    await fs.writeFile @config.pidfile(), "#{process.pid}", defer err
    if err? 
      ok = false
      @err "Error in making pidfile: #{err}"
    if ok
      log.daemonize @config.logfile()
      log.info "[pid #{process.pid}] starting up..."
    if ok
      # Set the password manager to not prompt for keys...
      @pwmgr.get_opts().bg = true
    cb ok

  #------------------------------

  init : (cb) ->
    await super defer ok
    await @listen defer ok if ok
    if @argv.daemon and ok
      await @daemonize defer ok
    cb ok

  #------------------------------

  run : (cb) ->
    await @init defer ok
    process.send { ok, err : @_e  }
    await @server.run defer()
    cb ok

#=========================================================================
