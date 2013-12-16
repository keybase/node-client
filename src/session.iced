
{env} = require './env'
req = require './req'
{E} = require './err'
{make_esc} = require 'iced-error'

#======================================================================

exports.Session = class Session 

  #-----

  constructor : () ->

  #-----
  
  get_id : (cb) ->
    err = ret = null
    if not (s = env().session)?
      err = new E.InternalError "no session object available"
    else
      ret = s.obj().session
    cb err, ret

  #-----

  check : (cb) ->
    logged_in = false
    if req.get_session()
      await req.get { endpoint : "sesscheck" }, defer err, body

      if not err? then logged_in = true
      else if err and (err instanceof E.KeybaseError) and (body?.status?.name is "BAD_SESSION")
        err = null
    cb err, logged_in

#======================================================================

exports.check = (cb) -> (new Session).check cb

#======================================================================
