db = require './db'
req = require './req'
log = require './log'
{constants} = require './constants'
{SHA256} = require './keyutils'
{E} = require './err'
{format_fingerprint,Warnings,asyncify} = require('pgp-utils').util
{make_esc} = require 'iced-error'
ST = constants.signature_types
ACCTYPES = constants.allowed_cryptocurrency_types
{dict_union,date_to_unix,make_email} = require './util'
proofs = require 'keybase-proofs'
cheerio = require 'cheerio'
request = require 'request'
colors = require './colors'
deq = require 'deep-equal'
util = require 'util'
fs = require 'fs'
{env} = require './env'
scrapemod = require './scrapers'
{CHECK,BTC} = require './display'
{athrow} = require('iced-utils').util
{merkle_client} = require './merkle_client'
bitcoyne = require 'bitcoyne'
{Link,LinkTable} = require('./chainlink')
{Proof,ProofSet} = require('libkeybase').assertion
libkeybase = require 'libkeybase'

##=======================================================================

exports.SigChain = class SigChain

  constructor : (@uid, @username, @_links = []) ->
    @_lookup = {}
    @_index_links @_links
    @_true_last = null

  #-----------

  _index_links : (list) ->
    for l in list
      @_lookup[l.id] = l

  #-----------

  lookup : (id) -> @_lookup[id]

  #-----------

  @load : (uid, username, curr, cb) ->
    log.debug "+ #{uid}: load signature chain"
    links = []
    err = null
    ret = null
    while curr and not err?
      log.debug "| #{uid}: Loading link #{curr}"
      await Link.load curr, defer err, link
      if err?
        log.error "Couldn't find link: #{last}"
        log.debug "| -> error"
      else if link?
        links.push link
        curr = link.prev()
        log.debug "| -> found link and previous; prev=#{curr}"
      else
        log.debug "| -> reached the chain end"
        curr = null
    unless err?
      ret = new SigChain uid, username, links.reverse()
    log.debug "- #{uid}: loaded signature chain"
    cb err, ret

  #-----------

  last_seqno : () -> if (l = @last())? then l.seqno() else null

  #-----------

  _update : (cb) ->
    log.debug "+ sigchain::_update"
    esc = make_esc cb, "_update"
    args = { @uid, low : (@last_seqno() + 1) }
    await req.get { endpoint : "sig/get", args }, esc defer body
    log.debug "| found #{body.sigs.length} new signatures"
    new_links = []
    did_update = false
    for obj in body.sigs
      link = Link.alloc { obj }
      await asyncify link.verify(), esc defer()
      new_links.push link
      did_update = true
    @_links = @_links.concat new_links
    @_new_links = new_links
    @_index_links new_links
    log.debug "- sigchain::_update"
    cb null, did_update

  #-----------

  store : (cb) ->
    err = null
    if @_new_links?.length
      log.debug "+ writing dirty signature chain"
      for link in @_new_links when not err?
        await link.store defer err
      log.debug "- wrote signature chain"
    cb err

  #-----------

  update : (remote_seqno, cb) ->
    err = null
    did_update = false
    if not (a = remote_seqno)? or a > (b = @last_seqno())
      log.debug "| sigchain update: #{a} vs. #{b}"
      await @_update defer err, did_update
      if remote_seqno? and ((a = remote_seqno) isnt (b = @last_seqno()))
        err = new E.CorruptionError "failed to appropriately update chain: #{a} != #{b}"
    cb err, did_update

  #-----------

  last : () ->
    if @_links?.length then @_links[-1...][0] else null

  #-----------

  # For the sake of signing a signature chain, we use the true last, and not
  # the effective last.  The effective last is what we get after removing the
  # links not signed by the current key.
  #
  # IF we haven't compressed yet, then the true last is simply the last
  true_last : () -> @_true_last or @last()

  #-----------

  # Given that I signed hash id `id`, is this still a fresh track?
  # The answer is yes if I signed the last link in the chain, or links
  # further back in the chain so long there were only TRACK and UNTRACK
  # signatures in between.
  is_track_fresh : (id) ->
    for l in @_links by -1
      if l.id is id then return true
      else if not (l.sig_type() in [ ST.TRACK, ST.UNTRACK ]) then return false
    return false

  #-----------

  _compress : ({verified_links, opts}) ->

    log.debug "+ compressing signature chain"

    out = new LinkTable()
    index = {}
    seq = {}

    for link in verified_links
      index[link.sig_id()] = link
      seq[link.seqno()] = link
      link.insert_into_table { table : out, index, opts }

    # Prune out revoked links
    unless opts.show_revoked
      out.prune (obj) -> obj.is_revoked()

    log.debug "- signature chain compressed"
    @table = out
    @index = index
    @seq = seq

  #-----------

  # list all remote proofs in a flat list, taking out the structure that
  # the Web and DNS proofs are in a sub-dictionary
  flattened_remote_proofs : () -> @table?.get(ST.REMOTE_PROOF)?.flatten() or []

  #-----------

  remote_proofs_to_track_obj : () ->
    links = @flattened_remote_proofs()
    (link.remote_proof_to_track_obj() for link in links when not link.is_revoked())

  #-----------

  merkle_root_to_track_obj : () ->
    if @_merkle_root?
      ret =
        hash : @_merkle_root.hash
        seqno : @_merkle_root.seqno
        ctime : @_merkle_root.ctime
    else
      ret = null
    return ret

  #-----------

  get_track_obj : (uid) -> @table?.get_path([ST.TRACK, uid])?.to_table_obj()

  #-----------

  verify_sig : ({opts, key, parsed_keys, merkle_data}, cb) ->
    esc = make_esc cb, "SigChain::verify_sig"
    @pubkey = key
    log.debug "+ #{@username}: verifying sig"
    sig_blobs = (link.obj for link in @_links)
    {eldest_kid} = merkle_data
    await libkeybase.SigChain.replay(
      {sig_blobs, parsed_keys, @uid, @username, eldest_kid, sig_cache: SigCache, log: log.debug},
      esc(defer(lkb_sig_chain)))

    # Check against seqno and sig_id from the Merkle tree.
    last_lkb_link = lkb_sig_chain.get_links()[-1...][0]
    if last_lkb_link?
      if last_lkb_link.sig_id != merkle_data.sig_id
        cb new Error "Last sig id (#{last_lkb_link.sig_id}) doesn't match the Merkle tree (#{merkle_data.sig_id})"
        return
      if last_lkb_link.seqno != merkle_data.seqno
        cb new Error "Last seqno (#{last_lkb_link.seqno}) doesn't match the Merkle tree (#{merkle_data.seqno})"
        return

    # Get the set of good seqnos from the verified sigchain.
    seqnos = {}
    for lkb_chain_link in lkb_sig_chain.get_links()
      seqnos[lkb_chain_link.seqno] = true

    # Filter our links based on that set.
    verified_links = (link for link in @_links when seqnos[link.seqno()])

    # Build the ID table.
    opts = opts or {}
    @_compress {opts, verified_links}

    # If an env var is set, write some debugging info about how
    # many unboxes we did.
    debug_file = process.env.KEYBASE_DEBUG_UNBOX_COUNT_FILE
    if debug_file?
      await fs.writeFile debug_file, "#{libkeybase.debug.unbox_count}", defer()

    log.debug "- #{@username}: verified sig"
    cb null, lkb_sig_chain.get_sibkeys({})

  #-----------

  list_trackees : () ->
    out = []
    if (tab = @table?.get(ST.TRACK)?.to_dict())
      for k,v of tab
        out.push v.payload_json()
    return out

  #-----------

  list_cryptocurrency_addresses : (opts = {}) ->
    out = null
    if (tab = @table?.get(ST.CRYPTOCURRENCY)?.to_dict())?
      for k,v of tab when (obj = v.to_cryptocurrency opts)?
        out or= {}
        out[obj.type] = obj.address
    return out

  #-----------

  list_remote_proofs : (opts = {}) ->
    out = null
    if (tab = @table?.get(ST.REMOTE_PROOF)?.to_dict())?
      for type,obj of tab
        type = proofs.proof_type_to_string[parseInt(type)]
        out or= {}

        # In the case of an end-link, just display it.  In the
        # case of a dictionary of more links, just list the keys
        out[type] = if (obj.is_leaf()) then obj.to_list_display(opts)
        else (v.to_list_display(opts) for k,v of obj.to_dict())

    return out

  #-----------

  display_cryptocurrency_addresses : (opts, cb) ->
    esc = make_esc cb, "SigChain::display_cryptocurrency_addresses"
    if (tab = @table?.get(ST.CRYPTOCURRENCY)?.to_dict())?
      for k,v of tab
        await v.display_cryptocurrency opts, esc defer()
    cb null

  #-----------

  check_assertions : ({gpg_keys, username, assertions, proof_vec}, cb) ->
    err = null
    for key in gpg_keys
      proof_vec.push(new Proof({key: "fingerprint", value: key.fingerprint().toString('hex')}))
    proof_vec.push(new Proof({ key : "keybase", value : username }))
    proof_set = new ProofSet proof_vec
    unless assertions.match_set proof_set
      err = new E.FailedAssertionError "Assertion set failed"
    cb err

  #-----------

  check_remote_proofs : ({skip, gpg_keys, assertions}, cb) ->
    esc = make_esc cb, "SigChain::check_remote_proofs"
    log.debug "+ #{@username}: checking remote proofs (skip=#{skip})"
    warnings = new Warnings()

    for key in gpg_keys
      msg = CHECK + " " + colors.green("public key fingerprint: #{format_fingerprint key.fingerprint().toString('hex')}")
      log.lconsole "error", log.package().INFO, msg

    n = 0

    # Keep track of all assertions in this key-value vector.
    proof_vec = []

    if (tab = @table?.get(ST.REMOTE_PROOF))?
      log.debug "| Loaded table with #{tab.keys().length} keys"
      for type,v of tab.to_dict()
        type = parseInt(type) # we expect it to be an int, not a dict key

        # For single-shot proofs like Twitter and Github, this will be the proof.
        # For multi-tenant proofs like 'generic_web_site', we have to go one level deeper
        links = v.flatten()

        for link in links
          await link.check_remote_proof { skip, type, warnings, proof_vec }, esc defer()
          n++
    else
      log.debug "| No remote proofs found"

    if assertions?
      await @check_assertions { gpg_keys, proof_vec, @username, assertions }, esc defer()

    log.debug "- #{@username}: checked remote proofs"
    cb null, warnings, n

##=======================================================================

# The libkeybase sigchain implementation accepts a cache object to speed up
# signature checking.
class SigCache
  @get : ({sig_id}, cb) ->
    esc = make_esc cb, "SigCache::get"
    await db.get { type: "sig_cache", key: sig_id, json: false }, esc defer payload_buffer
    cb null, payload_buffer

  @put : ({sig_id, payload_buffer}, cb) ->
    esc = make_esc cb, "SigCache::put"
    await db.put { type: "sig_cache", key: sig_id, value: payload_buffer, json: false }, esc defer()
    cb null
