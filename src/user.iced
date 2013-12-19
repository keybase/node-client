
req = require './req'
db = require './db'
{constants} = require './constants'
{make_esc} = require 'iced-error'
{E} = require './err'

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

  update_with : (remote, cb) ->
    esc = make_esc cb, "update_with"
    err = null

    a = @basics?.id_version
    b = remote?.basics?.id_version

    if not b? or a > b
      err = new E.VersionRollback "Server version-rollback suspected: Local #{a} > #{b}"
    else
      # do a deep-comparison
    cb err

  #--------------

  @load : ({username}, cb) ->
    esc = make_esc cb, "User::load"
    await User.load_from_server {username}, esc defer remote
    await User.load_from_storage {username}, esc defer local
    changed = true
    if local?
      await local.update_with remote, esc defer changed
    else if remote?
      local = remote
    else
      err = new E.UserNotFoundError "User #{username} wasn't found"
    if not err? and changed
      await local.store esc defer()
    cb err

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

