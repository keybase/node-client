db = require './db'
merkle = require 'merkle-tree'
req = require './req'
log = require './log'
{E} = require './err'
{make_esc} = require 'iced-error'
{a_json_parse,athrow} = require('iced-utils').util
{createHash} = require 'crypto'
{master_ring} = require './keyring'
keys = require './keys'
{env} = require './env'
C = require('./constants').constants
{Leaf} = require('libkeybase').merkle.leaf

#===========================================================

class MerkleClient extends merkle.Base

  @LATEST : "latest"

  #------

  constructor : () ->
    super {}
    @_root = null
    @_nodes = {}
    @_keys = {}
    @_verified = {}

  #------

  hash_fn : (s) -> 
    h = createHash('SHA512')
    h.update(s)
    ret = h.digest().toString('hex')
    ret

  #------

  lookup_root : (cb) ->
    err = hash = null
    unless @_root
      await req.get { endpoint : "merkle/root" }, defer err, body
      @_root = body unless err?
    hash = @_root.hash if @_root?
    cb err, hash, @_root

  #------

  store_node : (args, cb) -> @cb_unimplemented cb
  store_root : (args, cb) -> @cb_unimplemented cb

  #------

  cb_unimplemented : (cb) ->
    cb new E.UnimplementedError "not a storage engine"

  #------

  lookup_node : ({key}, cb) ->
    err = ret = null
    unless (ret = @_nodes[key])?
      args = { hash : key }
      await req.get { endpoint : "merkle/block", args }, defer err, body
      unless err?
        ret = @_nodes[key] = body.value
    cb err, ret

  #------

  verify_root_json : ({root}, cb) ->
    esc = make_esc cb, "MerkleClient::verify_root"
    await a_json_parse root.payload_json, esc defer json
    err = if (a = root.hash) isnt (b = json.body?.root)
      new E.VerifyError "Root hash mismatch: #{a} != #{b}"
    else if (a = root.seqno) isnt (b = json.body?.seqno)
      new E.VerifyError "Sequence # mismatch: #{a} != #{b}"
    else if (a = root.key_fingerprint?.toLowerCase()) isnt (b = json.body?.key?.fingerprint?.toLowerCase())
      new E.VerifyError "Fingerprint mismatch: #{a} != #{b}"
    else if (a = root.ctime) isnt (b = json.ctime)
      new E.VerifyError "Ctime mismatch: #{a} != #{b}"
    else 
      root.payload = json
      null
    cb err

  #------

  check_key_fingerprint : ( {fingerprint}, cb) ->
    if fingerprint in env().get_merkle_key_fingerprints()
      err = null
    else
      err = new E.KeyNotTrustedError "the fingerprint #{fingerprint} isn't trusted"
    cb err

  #------

  find_key_data : ({fingerprint}, cb) ->
    err = key_data = null
    if not (key_data = keys.lookup[fingerprint])?
      await req.get { endpoint : "key/special", args : { fingerprint } }, defer err, json
      if err? then # noop
      else if not (key_data = json.bundle)?
        err = new E.KeyNotFoundError "have no key for #{fingerprint}"
    cb err, key_data

  #------

  get_merkle_key : ({fingerprint}, cb) ->
    ring = master_ring()
    esc = make_esc cb, "MerkleCleint::get_merkle_key"
    err = ret = null
    log.debug "+ merkle get_merkle_key"
    unless (ret = @_keys[fingerprint])?
      await ring.index2 {}, esc defer index
      [err, obj] = index.lookup().fingerprint.get_0_or_1 fingerprint
      if err? then # noop
      else if obj? 
        log.debug "| merkle key already found in keyring"
        ret = ring.make_key { fingerprint }
      else
        await @find_key_data { fingerprint }, esc defer key_data
        log.debug "| doing a merkle key import for #{fingerprint}"
        ret = ring.make_key { fingerprint, key_data } 
        await ret.save esc defer()
        # Reset ret so that we need to reload the key by fingerprint. We 
        # don't want to trust that the key and fingerprint actually correspond.
        ret = ring.make_key { fingerprint }
      @_keys[fingerprint] = ret if ret?
    log.debug "- merkle get_merkle_key"
    cb err, ret

  #------

  rollback_check : ({root}, cb) ->
    log.debug "+ Rollback check"
    esc = make_esc cb, "MerkleClient::rollback_check"
    await @load_last_root esc defer last_root
    err = null
    if last_root? and (not (q = last_root.payload.body?.seqno)? or q > (p = root.payload.body?.seqno))
      err = new E.VersionRollbackError "Merkle root version rollback detected: #{q} > #{p}"
    else
      await @store_this_root { root } , esc defer()
    log.debug "- Rollback check"
    cb err

  #------

  store_this_root : ({root}, cb) ->
    pj = root.payload_json
    root.payload_json = null
    await db.put {
      type : C.ids.merkle_root
      key : root.hash
      value : root
      name : {
        type : C.lookups.merkle_root
        name : MerkleClient.LATEST
      }
      debug : true
    }, defer err
    root.payload_json = pj
    cb err

  #------

  load_last_root : (cb) ->
    await db.lookup { type : C.lookups.merkle_root, name : MerkleClient.LATEST }, defer err, obj
    cb err, obj

  #------

  verify_root : ({root}, cb) ->
    root or= @_root
    log.debug "+ merkle verify_root"
    err = null
    if not root?
      err = new E.NotFoundError 'no root found'
    else if @_verified[(rh = root.hash)]
      log.debug "| no need to verify root #{rh}; already verified"
    else
      fingerprint = root.key_fingerprint
      esc = make_esc cb, "Merkle::verify_root"
      await @check_key_fingerprint { fingerprint }, esc defer()
      await @get_merkle_key { fingerprint }, esc defer key
      await @verify_root_json { root }, esc defer()
      await key.verify_sig { which : "merkle root", sig : root.sig, payload : root.payload_json  }, esc defer()
      await @rollback_check { root }, esc defer()      
      @_verified[rh] = true
    log.debug "- merkle verify_root"
    cb err

  #------

  find_and_verify : ( { key }, cb) ->
    log.debug "+ merkle find_and_verify: #{key}"
    err = root = leaf = null
    await @find { key }, defer err, val, root
    log.debug "| find -> #{JSON.stringify val}"

    if err? then # noop
    else if not val? then err = new E.NotFoundError "No value #{key} found in merkle tree"
    else [err,leaf] = Leaf.parse val

    unless err?
      await @verify_root {root}, defer err

    log.debug "- merkle find_and_verify -> #{err}"

    cb err, leaf, root

#===========================================================

_merkle_client = null
exports.merkle_client = () ->
  _merkle_client = new MerkleClient() unless _merkle_client?
  return _merkle_client

#===========================================================
