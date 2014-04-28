
merkle = require 'merkle-tree'
req = require './req'
log = require './log'
{E} = require './err'
{make_esc} = require 'iced-utils'
{Lock} = require('iced-utils').lock
{createHash} = require 'crypto'

#===========================================================

class MerkleClient extends merkle.Base

  constructor : () ->
    super {}
    @_root = null
    @_nodes = {}
    @_lock = new Lock()

  #------

  hash_fn : (s) -> 
    h = createHash('SHA512')
    h.update(s)
    ret = h.digest().toString('hex')
    ret

  #------

  lookup_root : (cb) ->
    err = null
    unless @_root
      await req.get { endpoint : "merkle/root" }, defer err, body
      console.log "root"
      console.log body
      @_root = body unless err?
    cb err , @_root.hash

  #------

  store_node : (args, cb) ->
    cb new E.UnimplementedError "not a storage engine"

  #------

  store_root : (args, cb) ->
    cb new E.UnimplementedError "not a storage engine"

  #------

  lookup_node : ({key}, cb) ->
    err = ret = null
    unless (ret = @_nodes[key])?
      args = { hash : key }
      await req.get { endpoint : "merkle/block", args }, defer err, body
      console.log "block"
      console.log body
      unless err?
        ret = @_nodes[key] = body.value
    cb err, ret

  #------

  find : ({key}, cb) ->
    await @_lock.acquire defer()
    await super { key }, defer err, ret
    @_lock.release()
    cb err, ret, @_root

#===========================================================

_merkle_client = null
exports.merkle_client = () ->
  _merkle_client = new MerkleClient() unless _merkle_client?
  return _merkle_client

#===========================================================
