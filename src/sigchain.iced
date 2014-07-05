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
{env} = require './env'
scrapemod = require './scrapers'
{CHECK,BTC} = require './display'
{athrow} = require('iced-utils').util
{merkle_client} = require './merkle_client'
bitcoyne = require 'bitcoyne'
{Link,LinkTable} = require('./chainlink')

##=======================================================================

exports.SigChain = class SigChain 

  constructor : (@uid, @_links = []) ->
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

  @load : (uid, curr, cb) ->
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
      ret = new SigChain uid, links.reverse()
      if (err = ret.check_chain true)? then ret = null
    log.debug "- #{uid}: loaded signature chain"
    cb err, ret

  #-----------

  last_seqno : () -> if (l = @last())? then l.seqno() else null

  #-----------

  check_chain : (first, links) ->
    links or= @_links
    prev = null
    i =  0
    for link in links 
      if (prev? and (prev isnt link.prev())) or (not prev? and first and link.prev())
        return new E.CorruptionError "Bad chain link in #{link.seqno()}: #{prev} != #{link.prev()}"
      prev = link.id
    return null

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
    await asyncify (@check_chain (@_links.length is 0), new_links), esc defer()
    await asyncify (@check_chain false, (@_links[-1...].concat new_links[0..0])), esc defer()
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

  # Limit the chain to only those links signed by the key used in the last link
  _limit : () ->
    c = []
    log.debug "| input chain with #{n = @_links.length} link#{if n isnt 1 then 's' else ''}"
    for i in [(@_links.length-1)..0]
      if (l = @_links[i]).fingerprint()?.toLowerCase() is @fingerprint then c.push l
      else break
    c = c.reverse()
    if c.length isnt @_links.length
      log.debug "| Limited to #{n = c.length} link#{if n isnt 1 then 's' else ''}"
    @_links = c

 #--------------

  _verify_sig : (cb) ->
    err = null
    await l.verify_sig { which : @username, @pubkey }, defer err if (l = @last())?
    cb err

  #-----------

  _verify_userid : (cb) ->
    esc = make_esc cb, "_verify_userid"

    log.debug "+ _verify_userid for #{@username}"
    found = false
    kbem = make_email @username

    # first try to see if the username is baked into the key, and be happy with that
    log.debug "+ read username baked into key"
    await @pubkey.read_uids_from_key esc defer uids
    found = (email for {email} in uids).indexOf(kbem) >= 0
    log.debug "- found -> #{found}"

    log.debug "+ search for explicit self-signatures (found=#{found})"
    # Search for an explicit self-signature of this key
    if not found and (link = @table?.get(ST.SELF_SIG))? and (link.self_signer() is @username)
      found = true
    log.debug "- found -> #{found}"

    log.debug "+ search for a free-rider on a track signature (found=#{found})"
    # Search for a freerider in an otherwise useful signature
    if not found
      for type in [ ST.REMOTE_PROOF, ST.TRACK ] 
        tab = @table?.get(type)?.flatten() or []
        for link in tab
          if link.self_signer() is @username 
            found = true
            break
        break if found
    log.debug "- found -> #{found}"

    if not err? and not found
      msg = if env().is_me @username
        "You haven't signed your own key! Try `keybase push --update`"
      else "user '#{@username}' hasn't signed their own key"
      err = new E.VerifyError msg

    log.debug "- _verify_userid for #{@username} -> #{err}"
    cb err

  #-----------

  _compress : (opts) ->

    log.debug "+ compressing signature chain"

    out = new LinkTable()
    index = {}
    seq = {}

    for link in @_links when link.fingerprint() is @fingerprint
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

  verify_sig : ({key, opts}, cb) ->
    esc = make_esc cb, "SigChain::verify_sig"
    @username = username = key.username()
    @pubkey = key
    log.debug "+ #{username}: verifying sig"
    if (@fingerprint = key.fingerprint()?.toLowerCase())? and @last()?.fingerprint()?
      @_true_last = @last()
      @_limit()
      @_compress (opts or {})
      await @_verify_sig esc defer()
    else
      log.debug "| Skipped since no fingerprint found in key or no links in chain"
    await @_verify_userid esc defer()

    log.debug "- #{username}: verified sig"
    cb null

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

  check_merkle_tree : (cb) ->
    err = null
    lst = @true_last()
    log.debug "+ sigchain check_merkle_tree"
    if lst?
      await merkle_client().find_and_verify { key : @uid }, defer err, val, merkle_root
      unless err?
        [seqno, payload_hash] = val
        if (a = seqno) isnt (b = lst.seqno())
          err = new E.BadSeqnoError "bad sequence in root: #{a} != #{b}"
        else if (a = payload_hash) isnt (b = lst.id)
          err = new E.BadPayloadHash "bad payload hash in root: #{a} != #{b}"
        else
          @_merkle_root = merkle_root
    else
      log.debug "| no signatures for #{@uid}, so won't find in merkle tree; skipping check"
    log.debug "- sigchain check_merkle_tree"
    cb err

  #-----------

  display_cryptocurrency_addresses : (opts, cb) ->
    esc = make_esc cb, "SigChain::display_cryptocurrency_addresses"
    if (tab = @table?.get(ST.CRYPTOCURRENCY)?.to_dict())?
      for k,v of tab
        await v.display_cryptocurrency opts, esc defer()
    cb null

  #-----------

  check_remote_proofs : ({username, skip, pubkey, assertions}, cb) ->
    esc = make_esc cb, "SigChain::check_remote_proofs"
    log.debug "+ #{pubkey.username()}: checking remote proofs (skip=#{skip})"
    warnings = new Warnings()

    msg = CHECK + " " + colors.green("public key fingerprint: #{format_fingerprint pubkey.fingerprint()}")
    log.lconsole "error", log.package().INFO, msg
    n = 0

    # In case there was an assertion on the public key fingerprint itself...
    assertions?.found('key', false)?.success().set_payload pubkey.fingerprint() 
    assertions?.found('keybase', false)?.success().set_payload username

    if (tab = @table?.get(ST.REMOTE_PROOF))?
      log.debug "| Loaded table with #{tab.keys().length} keys"
      for type,v of tab.to_dict()
        type = parseInt(type) # we expect it to be an int, not a dict key

        # For single-shot proofs like Twitter and Github, this will be the proof.
        # For multi-tenant proofs like 'generic_web_site', we have to go one level deeper
        links = v.flatten()

        for link in links
          await link.check_remote_proof { skip, pubkey, type, warnings, assertions }, esc defer()
          n++
    else
      log.debug "| No remote proofs found"
    log.debug "- #{pubkey.username()}: checked remote proofs"
    cb null, warnings, n

##=======================================================================

