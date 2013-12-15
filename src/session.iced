
{env} = require './env'
req = require './req'
{E} = require './err'
{make_esc} = require 'iced-error'

#======================================================================

class Session 

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
    esc = make_esc cb, "Session::check"
    await @get_id esc defer id
    cb null

#======================================================================
