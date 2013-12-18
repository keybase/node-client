
req = require './req'

##=======================================================================

exports.User = class User 

  #--------------

  constructor : ({@basics, @public_keys, @id}) ->

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

##=======================================================================

