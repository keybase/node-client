{proof_type_to_string,constants} = require './constants'
pgp_utils = require('pgp-utils')
{trim,katch,akatch,bufeq_secure,json_stringify_sorted,unix_time,base64u,streq_secure} = pgp_utils.util
triplesec = require('triplesec')
{WordArray} = triplesec
{SHA256} = triplesec.hash
kbpgp = require 'kbpgp'
{make_esc} = require 'iced-error'
util = require 'util'
{base64_extract} = require './b64extract'

#==========================================================================

exports.hash_sig = hash_sig = (sig_body) ->
  (new SHA256).bufhash(sig_body)

#------

add_ids = (sig_body, out) ->
  hash = hash_sig sig_body
  id = hash.toString('hex')
  short_id = sig_id_to_short_id hash
  out.id = id
  out.med_id = sig_id_to_med_id hash
  out.short_id = short_id

#------

make_ids = (sig_body) ->
  out = {}
  add_ids sig_body, out
  return out

#------

sig_id_to_med_id = (sig_id) -> base64u.encode sig_id

#------

sig_id_to_short_id = (sig_id) ->
  base64u.encode sig_id[0...constants.short_id_bytes]

#================================================================================

proof_text_check_to_med_id = (proof_text_check) ->
  {med_id} = make_ids(new Buffer proof_text_check, 'base64')
  med_id

#================================================================================

exports.cieq = cieq = (a,b) -> (a? and b? and (a.toLowerCase() is b.toLowerCase()))

#==========================================================================

class Verifier

  constructor : ({@armored, @id, @short_id, @skip_ids, @make_ids, @strict}, @sig_eng, @base) ->

  #---------------

  km : () -> @sig_eng.get_km()

  #---------------

  get_etime : () ->
    if @json.ctime? and @json.expire_in then (@json.ctime + @json.expire_in)
    else null

  #---------------

  verify : (cb) ->
    esc = make_esc cb, "Verifier::verfiy"
    await @_parse_and_process esc defer()
    await @_check_json esc defer json_obj, json_str
    await @_check_expired esc defer()
    cb null, json_obj, json_str

  #---------------

  _check_ids : (body, cb) ->
    {short_id, id} = make_ids body
    err = if not (@id? and streq_secure id, @id)
      new Error "Long IDs aren't equal; wanted #{id} but got #{@id}"
    else if not (@short_id? and streq_secure short_id, @short_id)
      new Error "Short IDs aren't equal: wanted #{short_id} but got #{@short_id}"
    else null
    cb err

  #---------------

  _check_expired : (cb) ->
    err = null
    now = unix_time()
    if not @json.ctime? then err = new Error "No `ctime` in signature"
    else if not @json.expire_in? then err = new Error "No `expire_in` in signature"
    else if not @json.expire_in then @etime = null
    else if (expired = (now - @json.ctime - @json.expire_in)) > 0
      err = new Error "Expired #{expired}s ago"
    else
      @etime = @json.ctime + @json.expire_in
    cb err

  #---------------

  _parse_and_process : (cb) ->
    err = null
    await @sig_eng.unbox @armored, defer err, @payload, body
    if not err? and not @skip_ids
      await @_check_ids body, defer err
    if not err? and @make_ids
      {@short_id, @id} = make_ids body
    cb err

  #---------------

  _check_json : (cb) ->
    json_str_buf = @payload

    # Before we run any checks on the input json, let's trim any leading
    # or trailing whitespace.
    json_str_utf8 = json_str_buf.toString('utf8')
    json_str_utf8_trimmed = trim json_str_utf8
    err = null
    if not /^[\x20-\x7e]+$/.test json_str_utf8_trimmed
      err = new Error "All JSON proof characters must be in the visible ASCII set (properly escaped UTF8 is permissible)"
    else
      [e, @json] = katch (() -> JSON.parse json_str_buf)
      err = new Error "Couldn't parse JSON signed message: #{e.message}" if e?
      if not err?
        if @strict and ((ours = trim(json_stringify_sorted(@json))) isnt json_str_utf8_trimmed)
          err = new Error "non-canonlical JSON found in strict mode (#{ours} v #{json_str_utf8_trimmed})"
        else
          await @base._v_check {@json}, defer err
    cb err, @json, json_str_utf8

#==========================================================================

class Base

  #------

  constructor : ({@sig_eng, @seqno, @user, @host, @prev, @client, @merkle_root, @revoke, @seq_type, @eldest_kid, @expire_in, @ctime}) ->

  #------

  proof_type_str : () ->
    if (t = @proof_type())? then proof_type_to_string[t]
    else null

  #------

  _v_check_key : (key) ->
    checks = 0
    if key?.kid?
      checks++
      err = @_v_check_kid key.kid
    if not err? and key?.fingerprint?
      checks++
      err = @_v_check_fingerprint key
    if not err?  and checks is 0
      err = new Error "need either a 'body.key.kid' or a 'body.key.fingerprint'"
    err

  #------

  _v_check_kid : (kid) ->
    if not bufeq_secure (a = @km().get_ekid()), (new Buffer kid, "hex")
      err = new Error "Verification key doesn't match packet (via kid): #{a.toString('hex')} != #{kid}"
    else
      null

  #------

  _v_check_fingerprint : (key) ->
    if not (key_id = key?.key_id)?
      new Error "Needed a body.key.key_id but none given"
    else if not bufeq_secure (a = @km().get_pgp_key_id()), (new Buffer key_id, "hex")
      new Error "Verification key doesn't match packet (via key ID): #{a.toString('hex')} != #{key_id}"
    else if not (fp = key?.fingerprint)?
      new Error "Needed a body.key.fingerprint but none given"
    else if not bufeq_secure @km().get_pgp_fingerprint(), (new Buffer fp, "hex")
      new Error "Verifiation key doesn't match packet (via fingerprint)"
    else
      null

  #------

  # true if PGP details (full_hash and fingerprint) should be inserted at
  # @_v_pgp_details_dest()
  _v_include_pgp_details : -> false

  # true if this link type is only valid if it includes PGP details
  _v_require_pgp_details : -> false

  # Given the JSON body, the object where PGP key details should end up
  _v_pgp_details_dest : (body) -> body.key

  # If @_v_include_pgp_details() is true, a KeyManager containing a PGP key
  _v_pgp_km : () -> null

  # Generates (and caches) a hash for PGP keys, returns null for other kinds of keys
  full_pgp_hash : (opts, cb) ->
    if @_full_pgp_hash is undefined
      esc = make_esc cb
      await @_v_pgp_km()?.pgp_full_hash {}, esc defer @_full_pgp_hash
    cb null, @_full_pgp_hash

  # Adds the PGP hash and fingerprint to `body`. Noop for non-PGP keys (unless
  # @_v_require_pgp_details returns true, then returns an error.)
  _add_pgp_details : ({body}, cb) ->
    return cb(null) unless @_v_include_pgp_details()

    dest = @_v_pgp_details_dest(body)
    await @full_pgp_hash {}, defer err, full_hash
    if err then # noop
    else if full_hash?
      dest.full_hash = full_hash
      dest.fingerprint = @_v_pgp_km().get_pgp_fingerprint().toString('hex') unless dest.fingerprint?
    else if @_v_require_pgp_details()
      err = new Error "#{@proof_type_str()} proofs require a PGP key"

    cb err

  _check_pgp_details: ({json}, cb) ->
    err = null
    details = @_v_pgp_details_dest(json.body)

    if not (hash_in = details?.full_hash)? or not (fp_in = details?.fingerprint)? or not (kid_in = details?.kid)?
      if @_v_require_pgp_details()
        err = new Error "#{@proof_type_str()} proofs require a PGP key's KID, fingerprint, and full_hash but one or more were missing."
    else
      await @full_pgp_hash {}, defer err, hash_real
      if err? then # noop
      else if not hash_real?
        err = new Error "A PGP key hash (#{hash_in}) was in the sig body but no key was provided"
      else if hash_in isnt hash_real
        err = new Error "New PGP key's hash (#{hash_real}) doesn't match hash in signature (#{hash_in})"
      else if fp_in isnt (fp_real = @_v_pgp_km().get_pgp_fingerprint().toString('hex'))
        err = new Error "New PGP key's fingerprint (#{fp_real}) doesn't match fingerprint in signature (#{fp_in})"
      else if kid_in isnt (kid_real = @_v_pgp_km().get_ekid().toString('hex'))
        err = new Error "New PGP key's KID (#{kid_real}) doesn't match KID in signature (#{kid_in})"

    cb err

  #------

  _v_check : ({json}, cb) ->

    # The default seq_type is PUBLIC
    seq_type = (v) -> if v? then v else constants.seq_types.PUBLIC

    err = if not cieq (a = json?.body?.key?.username), (b = @user.local.username)
      new Error "Wrong local user: got '#{a}' but wanted '#{b}'"
    else if (a = json?.body?.key?.uid) isnt (b = @user.local.uid)
      new Error "Wrong local uid: got '#{a}' but wanted '#{b}'"
    else if not cieq (a = json?.body?.key?.host), (b = @host)
      new Error "Wrong host: got '#{a}' but wanted '#{b}'"
    else if (a = @_type())? and ((b = json?.body?.type) isnt a)
      # Don't check if it's a "generic_binding", which doesn't much
      # care what the signature type is.  Imagine the case of just trying to
      # get the user's keybinding.  Then any signature will do.
      new Error "Wrong signature type; got '#{a}' but wanted '#{b}'"
    else if (a = @prev) and (a isnt (b = json?.prev))
      new Error "Wrong previous hash; wanted '#{a}' but got '#{b}'"
    else if (a = @seqno) and (a isnt (b = json?.seqno))
      new Error "Wrong seqno; wanted '#{a}' but got '#{b}"
    else if @seqno and (a = seq_type(json?.seq_type)) isnt (b = seq_type(@seq_type))
      new Error "Wrong seq_type: wanted '#{a}' but got '#{b}'"
    else if not (key = json?.body?.key)?
      new Error "no 'body.key' block in signature"
    else if (section_error = @_check_sections(json))?
      section_error
    else
      @_v_check_key key

    if not err?
      await @_check_pgp_details {json}, defer err

    cb err

  #------

  _required_sections : () -> ["key", "type", "version"]

  #------

  _optional_sections : () -> ["client", "merkle_root"]
  _is_wildcard_link : () -> false

  #------

  # Return a JavaScript Error on failure, or null if no failure.
  _check_sections : (json) ->
    for section in @_required_sections()
      unless json?.body?[section]
        return new Error "Missing '#{section}' section #{if json.seqno? then "in seqno " + json.seqno else ""}, required for #{json.body.type} signatures"

    # Sometimes we don't really need to check, we just need a "key" section
    unless @_is_wildcard_link()
      for section, _ of json?.body
        unless (section in @_required_sections()) or (section in @_optional_sections())
          return new Error "'#{section}' section #{if json.seqno? then "in seqno " + json.seqno else ""} is not allowed for #{json.body.type} signatures"

    null

  #------

  is_remote_proof : () -> false

  #------

  has_revoke : () ->
    if not @revoke? then false
    else if @revoke.sig_id? then true
    else if (@revoke.sig_ids?.length > 0) then true
    else if @revoke.kid? then true
    else if (@revoke.kids?.length > 0) then true
    else false

  #------

  _v_customize_json : (ret) ->

  #------

  generate_json : ({expire_in} = {}, cb) ->
    err = null

    # Cache the unix_time() we generate in case we need to call @generate_json()
    # twice.  This happens for reverse signatures!
    ctime = if @ctime? then @ctime else (@ctime = unix_time())

    pick = (v...) ->
      for e in v when e?
        return e
      return null

    ret = {
      seqno : @seqno
      prev : @prev
      ctime : ctime
      tag : constants.tags.sig
      expire_in : pick(expire_in, @expire_in, constants.expire_in)
      body :
        version : constants.versions.sig
        type : @_type()
        key :
          host : @host
          username : @user.local.username
          uid : @user.local.uid
    }

    # Can't access ekids from GnuPG. We'd have to parse the keys (possible).
    if (ekid = @km().get_ekid())?
      ret.body.key.kid = ekid.toString('hex')

    if (fp = @km().get_pgp_fingerprint())?
      ret.body.key.fingerprint = fp.toString('hex')
      ret.body.key.key_id = @km().get_pgp_key_id().toString('hex')

    if @eldest_kid?
      ret.body.key.eldest_kid = @eldest_kid

    # Can be:
    #
    #   NONE : 0
    #   PUBLIC : 1  # this is the default!
    #   PRIVATE : 2
    #   SEMIPRIVATE : 3
    #
    ret.seq_type = @seq_type if @seq_type?

    ret.body.client = @client if @client?
    ret.body.merkle_root = @merkle_root if @merkle_root?
    ret.body.revoke = @revoke if @has_revoke()

    @_v_customize_json ret

    await @_add_pgp_details {body: ret.body}, defer err

    cb err, json_stringify_sorted ret

  #------

  _v_generate : (opts, cb) -> cb null

  #------

  generate : (cb) ->
    esc = make_esc cb, "generate"
    out = null
    await @_v_generate {}, esc defer()
    await @generate_json {}, esc defer json
    await @sig_eng.box json, esc defer {pgp, raw, armored}
    {short_id, id} = make_ids raw
    out = { pgp, json, id, short_id, raw, armored }
    cb null, out

  #------

  # @param {Object} obj with options as specified:
  # @option obj {string} pgp The PGP signature that's being uploaded
  # @option obj {string} id The keybase-appropriate ID that's the PGP signature's hash
  # @option obj {string} short_id The shortened sig ID that's for the tweet (or similar)
  # @option obj {bool} skip_ids Don't bother checking IDs
  # @option obj {bool} make_ids Make Ids when verifying
  # @option obj {bool} strict Turn on all strict-mode checks
  verify : (obj, cb) ->
    verifier = new Verifier obj, @sig_eng, @
    await verifier.verify defer err, json_obj, json_str
    id = short_id = null
    if obj.make_ids
      id = obj.id = verifier.id
      short_id = obj.short_id = verifier.short_id
    out = if err? then {}
    else {json_obj, json_str, id, short_id, etime : verifier.get_etime(), @reverse_sig_kid }
    cb err, out

  #-------

  km : () -> @sig_eng.get_km()

  #-------

  check_inputs : () -> null

  #-------

  # Check this proof against the existing proofs
  check_existing : () -> null

  #-------

  # Some proofs are shortened, like Twitter, due to the space-constraints on the medium.
  is_short : () -> false

  #-------

  # Check the server's work when we ask for it to generate a proof text.
  # Make sure our sig shows up in there but no one else's.  This will
  # vary between long and short signatures.
  sanity_check_proof_text : ({ args, proof_text}, cb) ->
    if @is_short()
      check_for = args.sig_id_short
      len_floor = constants.short_id_bytes
      slack = 3
    else
      [ err, msg ] = kbpgp.ukm.decode_sig { armored: args.sig }
      if not err? and (msg.type isnt kbpgp.const.openpgp.message_types.generic)
        err = new Error "wrong message type; expected a generic message; got #{msg.type}"
      if not err?
        check_for = msg.body.toString('base64')
        len_floor = constants.shortest_pgp_signature
        slack = 30 # 30 bytes of prefix/suffix data available
    unless err?
      b64s = base64_extract proof_text
      for b in b64s when (b.length >= len_floor)
        if b.indexOf(check_for) < 0 or (s = (b.length - check_for.length)) > slack
          err = new Error "Found a bad signature in proof text: #{b[0...60]} != #{check_for[0...60]} (slack=#{s})"
          break
    cb err

#==========================================================================

class GenericBinding extends Base
  _type : () -> null
  resource_id : () -> ""
  _service_obj_check : () -> true
  _is_wildcard_link : () -> true

#==========================================================================

exports.Base = Base
exports.GenericBinding = GenericBinding
exports.sig_id_to_short_id = sig_id_to_short_id
exports.sig_id_to_med_id = sig_id_to_med_id
exports.make_ids = make_ids
exports.add_ids = add_ids
exports.proof_text_check_to_med_id = proof_text_check_to_med_id

#==========================================================================

