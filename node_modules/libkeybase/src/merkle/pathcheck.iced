
C = require '../constants'
{make_esc} = require 'iced-error'
{hash} = require 'triplesec'
merkle = require 'merkle-tree'
{a_json_parse} = require('iced-utils').util
{Leaf} = require './leaf'

sha256 = (s) -> (new hash.SHA256).bufhash(new Buffer s, 'utf8').toString('hex')
sha512 = (s) -> (new hash.SHA512).bufhash(new Buffer s, 'utf8').toString('hex')

#===========================================================

#
# pathcheck
#
# Given a reply from the server, and a keymanager that can verify the
# reply, check the signature, check the path from the root the leaf,
# check the username, and then callback.
#
# @param server_reply {Object} the JSON object the server sent back
# @param km {KeyManager} a keyManager to verify the reply with
# @param cb {Callback<err,{Leaf,Uid,Username}>} Reply with the Leaf, uid,
#   and username verified by the merkle path
module.exports = pathcheck = ({server_reply, km}, cb) ->
  pc = new PathChecker { server_reply, km }
  await pc.run defer err, res
  cb err, res

#===========================================================

class PathChecker

  constructor : ({@server_reply, @km}) ->

  #-----------

  run : (cb) ->
    esc = make_esc cb, "PathChecker::run"
    await @_verify_sig esc defer()
    await @_verify_username esc defer uid, username
    await @_verify_path {uid}, esc defer leaf
    cb null, {leaf, uid, username}

  #-----------

  _verify_sig : (cb) ->
    esc = make_esc cb, "_verify_sig"
    kid = @km.get_ekid().toString('hex')
    err = null
    unless (sig = @server_reply.root.sigs[kid]?.sig)?
      err = new Error "No signature found for kid: #{kid}"
    else
      sigeng = @km.make_sig_eng()
      await sigeng.unbox sig, esc defer raw
      await a_json_parse raw.toString('utf8'), esc defer @_signed_payload
    cb err

  #-----------

  _extract_nodes : ({list}, cb) ->
    esc = make_esc cb, "PathChecker::_extract_nodes"
    ret = {}
    for {node} in list
      await a_json_parse node.val, esc defer val
      ret[node.hash] = val
    cb null, ret

  #-----------

  _verify_username_legacy : ({uid, username}, cb) ->
    esc = make_esc cb, "PathChecker::_verify_username_legacy"
    root = @_signed_payload.body.legacy_uid_root
    await @_extract_nodes {list : @server_reply.uid_proof_path}, esc defer nodes
    tree = new LegacyUidNameTree { root, nodes }
    await tree.find {key : sha256(username) }, esc defer leaf
    err = if (leaf is uid) then null
    else new Error "UID mismatch #{leaf} != #{uid} in tree for #{username}"
    cb err

  #-----------

  _verify_path : ({uid}, cb) ->
    esc = make_esc cb, "PathChecker::_verify_path"
    root = @_signed_payload.body.root
    await @_extract_nodes { list : @server_reply.path}, esc defer nodes
    tree = new MainTree { root, nodes }
    await tree.find {key : uid}, esc defer leaf_raw
    # The leaf might be missing entirely, for empty users.
    if leaf_raw?
      [err, leaf] = Leaf.parse leaf_raw
    else
      [err, leaf] = [null, null]
    cb err, leaf

  #-----------

  _verify_username : (cb) ->
    {uid,username,username_cased} = @server_reply
    err = null

    if uid[-2...] is '00'
      await @_verify_username_legacy {username,uid}, defer err

    else
      err = @_verify_username_hash { uid, username, lc : false }
      if err? and username_cased? and
          (username_cased isnt username) and 
          (username_cased.toLowerCase() is username)
        err = @_verify_username_hash { uid, username : username_cased }

    cb err, uid, username

  #-----------

  _verify_username_hash : ( {uid, username}) ->
    h = (new hash.SHA256).bufhash (new Buffer username, "utf8")
    uid2 = h[0...15].toString('hex') + '19'
    if (uid isnt uid2)
      err = new Error "bad UID: #{uid} != #{uid2} for username #{username}"
    return err

#===========================================================

class BaseTree extends merkle.Base

  constructor : ({@root, @nodes}) ->
    super {}

  lookup_root : (cb) ->
    cb null, @root

  lookup_node : ({key}, cb) ->
    ret = @nodes[key]
    err = if ret? then null else new Error "key not found: '#{key}'"
    cb err, ret

#===========================================================

class LegacyUidNameTree extends BaseTree

  hash_fn : (s) -> sha256 s

#===========================================================

class MainTree extends BaseTree

  hash_fn : (s) -> sha512 s

#===========================================================

__iced_k_noop()
