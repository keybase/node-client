
req = require './req'
db = require './db'
{constants} = require './constants'
{make_esc} = require 'iced-error'

##=======================================================================

exports.User = class User 

  #--------------

  constructor : ({@basics, @public_keys, @id, @sigs}) ->

  #--------------

  to_obj : () -> { @basics, @public_keys, @id, @sigs }

  #--------------

  name : () -> { type : constants.lookups.username, name : @basics.username }

  #--------------

  store : (cb) ->
    await db.put { key : @id, value : @to_obj(), name : @name() }, defer err
    cb err

  #--------------

  @load : ({username}, cb) ->
    esc = make_esc cb, "User::load"
    await User.load_from_server {username}, esc defer remote
    await User.load_from_storage {username}, esc defer local
    if remote? and not local?
      await remote.store esc defer()
    console.log remote
    console.log local
    cb null, { local, remote }

  #--------------

  @load_from_server : ({username}, cb) ->
    args = 
      endpoint : "user/lookup"
      args : {username }
    await req.get args, defer err, body
    ret = null
    unless err?
      ret = new User body.them
    cb err, ret

  #--------------

  @load_from_storage : ({username}, cb) ->
    ret = null
    await db.lookup { type : constants.lookups.username, name: username }, defer err, row
    if not err? and row?
      ret = new User row.value
    cb err, ret

##=======================================================================

