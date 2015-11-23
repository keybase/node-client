db = require './db'
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
pathcheck = require('libkeybase').merkle.pathcheck
{Leaf} = require('libkeybase').merkle.leaf
kbpgp = require 'kbpgp'

#===========================================================

class MerkleClient

  @LATEST : "latest"

  #------

  constructor : () ->
    @_nodes = {}
    @_keys = {}
    @_verified = {}

  #------

  lookup_path : ({uid, username}, cb) ->
    if not uid? and not username?
      cb new Error "lookup_path: one of uid or username must be specified"
      return
    if uid? and username?
      cb new Error "lookup_path: only one of uid (#{uid}) and username (#{username}) can be specified"
      return
    req.get { endpoint : "merkle/path", args: {uid, username} }, cb

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

  get_merkle_pgp_key : ({fingerprint}, cb) ->
    ring = master_ring()
    esc = make_esc cb, "MerkleClient::get_merkle_pgp_key"
    err = ret = null
    log.debug "+ merkle get_merkle_pgp_key"
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
    log.debug "- merkle get_merkle_pgp_key"
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
    cb err

  #------

  load_last_root : (cb) ->
    await db.lookup { type : C.lookups.merkle_root, name : MerkleClient.LATEST }, defer err, obj
    cb err, obj

  #------

  get_merkle_key_manager : ( {path_response}, cb ) ->
    esc = make_esc cb, "MerkleClient::get_merkle_key_manager"
    fingerprint = null
    for kid, blob of path_response.root.sigs
      if blob.fingerprint?
        fingerprint = blob.fingerprint
        break
    if not fingerprint?
      await athrow (new Error("Didn't find a PGP fingerprint among the merkle sigs.")), esc defer()
    await @check_key_fingerprint {fingerprint}, esc defer()
    await @get_merkle_pgp_key { fingerprint }, esc defer pgp_key
    await pgp_key.load esc defer()  # key_data() will be empty if load() is not called
    armored = pgp_key.key_data()
    await kbpgp.KeyManager.import_from_armored_pgp {armored}, esc defer key_manager
    cb null, key_manager

  #------

  get_root_with_parsed_payload : ({root_from_server}, cb) ->
    esc = make_esc cb, "MerkleClient::get_root_with_parsed_payload"
    # Older code edited the format of the root blob that ended up on disk. This
    # method maintains compatibility with that.
    root_clone = {}
    root_clone[k] = v for k, v of root_from_server
    await a_json_parse root_clone.payload_json, esc defer payload
    root_clone.payload_json = null
    root_clone.payload = payload
    cb null, root_clone

  #------

  find_and_verify : ( { uid, username }, cb) ->
    esc = make_esc cb, "MerkleClient::find_and_verify"
    username = username.toLowerCase()
    log.debug "+ merkle find_and_verify: uid #{uid}, username #{username}"
    await @lookup_path { uid, username }, esc defer path_response
    await @get_merkle_key_manager {path_response}, esc defer km
    await pathcheck {server_reply: path_response, km}, esc defer pathcheck_result
    if uid? and pathcheck_result.uid != uid
      await athrow (new Error "Expected uid #{uid} does not match merkle response uid #{pathcheck_result.uid}"), esc defer()
    if username? and pathcheck_result.username != username
      await athrow (new Error "Expected username #{username} does not match merkle response username #{pathcheck_result.username}"), esc defer()
    await @get_root_with_parsed_payload { root_from_server: path_response.root }, esc defer root
    await @rollback_check { root }, esc defer()
    cb null, pathcheck_result.leaf, root, path_response.id_version

#===========================================================

_merkle_client = null
exports.merkle_client = () ->
  _merkle_client = new MerkleClient() unless _merkle_client?
  return _merkle_client

#===========================================================
