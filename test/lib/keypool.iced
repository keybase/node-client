
{AltKeyRing} = require('gpg-wrapper').keyring
path = require 'path'

#===================================================

class Keypool

  constructor : () -> 
    @_keyring = new AltKeyRing path.join __dirname, "..", "keypool"
    @_keys = null

  load : (cb) ->
    await @_keyring.find_keys_full { secret : true }, defer err, @_keys
    cb err

  grab : (cb) -> 
    err = ret = null
    if @_keys?.length then ret = @_keys[7]
    else err = new Error "no keys left"
    cb err, ret

#===================================================

_keypool = null
exports.grab = grab = (cb) ->
  err = key = null
  if not _keypool
    _keypool = new Keypool
    await _keypool.load defer err
  unless err?
    await _keypool.grab defer err, key
  cb err, key

#===================================================
