
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

#===========================================================

class MerkleClient extends merkle.Base

  constructor : () ->
    super {}
    @_root = null
    @_nodes = {}
    @_keys = {}

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
      unless err?
        @_root = body
        hash = body.hash
    cb err, hash

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
    console.log json
    err = if (a = root.hash) isnt (b = json.body?.root)
      new E.VerifyError "Root hash mismatch: #{a} != #{b}"
    else if (a = root.seqno) isnt (b = json.body?.seqno)
      new E.VerifyError "Sequence # mismatch: #{a} != #{b}"
    else if (a = root.key_fingerprint?.toLowerCase()) isnt (b = json.body?.key?.fingerprint?.toLowerCase())
      new E.VerifyError "Fingerprint mismatch: #{a} != #{b}"
    else 
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

  get_merkle_key : ({fingerprint}, cb) ->
    ring = master_ring()
    esc = make_esc cb, "MerkleCleint::get_merkle_key"
    err = ret = null
    unless (ret = @_keys[fingerprint])?
      await ring.index2 { query : fingerprint }, esc defer index
      [err, obj] = index.lookup().fingerprint.get_0_or_1 fingerprint
      if err? then # noop
      else if obj? 
        ret = ring.make_key { fingerprint }
      else if not (key_data = keys.lookup[fingerprint])?
        err = new E.KeyNotFoundError "have no key for #{fingerprint}"
      else
        ret = ring.make_key { fingerprint, key_data } 
        await ret.save esc defer()
      @_keys[fingerprint] = ret if ret?
    cb err, ret

  #------

  verify_root : ({root}, cb) ->
    root or= @_root
    esc = make_esc cb, "MerkleClient::verify_root"
    fingerprint = root.key_fingerprint
    await @check_key_fingerprint { fingerprint }, esc defer()
    await @get_merkle_key { fingerprint }, esc defer key
    await @verify_root_json { root }, esc defer()
    await key.verify_sig { which : "merkle root", sig : root.sig, payload : root.payload_json  }, esc defer()
    cb null

  #------

  find_and_verify : ( { key }, cb) ->
    log.debug "+ merkle find_and_verify: #{key}"
    await @find { key }, defer err, val, root
    log.debug "| find -> #{JSON.stringify val}"
    if err? then # noop
    if not val? then err = new E.NotFoundError "No value #{key} found in merkle tree"
    else if not Array.isArray(val) or val.length < 2 
      err = new E.BadValueError "expected an array of length 2 or more"
    else 
      await @verify_root {root}, defer err
    log.debug "- merkle find_and_verify -> #{err}"

    cb err, val, root

#===========================================================

_merkle_client = null
exports.merkle_client = () ->
  _merkle_client = new MerkleClient() unless _merkle_client?
  return _merkle_client

#===========================================================
