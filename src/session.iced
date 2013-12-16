
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
    await req.get { endpoint : "sesscheck" }, defer err, body
    console.log err
    cb null

#======================================================================

exports.check = (cb) -> (new Session).check cb

#======================================================================
