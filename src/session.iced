
{env} = require './env'
req = require './req'
{E} = require './err'
{make_esc} = require 'iced-error'
{Config} = require './config'

#======================================================================

exports.Session = class Session 

  #-----

  constructor : () ->
    @_file = null
    @_loaded = false
    @_id = null

  #-----

  load : (cb) ->
    unless @_file
      @_file = new Config env().get_session_filename(), { quiet : true }
    await @_file.opn defer err
    if not err? and @_file.found and (s = @_file.obj()?.session)?
      req.set_session s
    cb err

  #-----

  set_id : (s) ->
    @_id = s
    req.set_session s
    @_file.set "session", s

  #-----

  write : (cb) ->
    err = null
    await @load        defer err unless @_loaded
    await @_file.write defer err unless err?
    cb err

  #-----

  get_id : () -> @_id or @_file?.obj()?.session

  #-----

  check : (cb) ->
    @_logged_in = false
    if req.get_session()
      await req.get { endpoint : "sesscheck" }, defer err, body
      if not err? then @_logged_in = true
      else if err and (err instanceof E.KeybaseError) and (body?.status?.name is "BAD_SESSION")
        err = null
    cb err, @_logged_in

#======================================================================

_session = new Session

module.exports = 
  Session        : Session
  session        : _session
  load           : (args...) -> _session.check args...
  check          : (args...) -> _session.check args...

#======================================================================
