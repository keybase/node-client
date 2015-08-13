
C = require '../constants'

#===========================================================

exports.ChainTail = class ChainTail
  constructor : ({@seqno, @payload_hash, @sig_id }) ->
  to_json : () -> [ @seqno, @payload_hash, @sig_id ]

#--------------------------

class Parser

  constructor : (@val) ->

  parse : () ->

    if not Array.isArray(@val) or @val.length < 1
      throw new Error "Expected an array of length 1 or more"
    else if typeof(@val[0]) isnt 'number'
      throw new Error "Need a number for first slot"
    else if typeof(@val[1]) is 'string'
      # We messed up and didn't version the initial leafs of the tree
      version = 1
    else
      version = @val[0]

    switch version
      when C.versions.leaf.v1 then @parse_v1()
      when C.versions.leaf.v2 then @parse_v2()
      else throw new Error "unknown leaf version: #{version}"

  parse_v1 : () ->
    pub = @parse_chain_tail @val
    new Leaf { pub }

  parse_v2 : () ->
    if @val.length < 2 then throw new Error "No public chain"
    pub = if (@val.length > 1 and @val[1]?.length) then @parse_chain_tail(@val[1]) else null
    semipriv = if (@val.length > 2) and @val[2]?.length then @parse_chain_tail(@val[2]) else null
    eldest_kid = if (@val.length > 3 and @val[3]?) then @parse_kid(@val[3]) else null
    return new Leaf { pub, semipriv, eldest_kid }

  match_hex : (s) ->
    (typeof(s) is 'string') and !!(s.match(/^([a-fA-F0-9]*)$/)) and (s.length % 2 is 0)

  parse_kid : (x) ->
    throw new Error "bad kid: #{x}" unless @match_hex x
    return x

  parse_chain_tail : (val) ->
    msg = null
    if (val.length < 2) then msg = "Bad chain tail with < 2 values"
    else if typeof(val[0]) isnt 'number' then msg = "Bad sequence #"
    else
      # Slots #1,2 are both HexIds. We don't know what 3+ will be
      for v,i in val[1..2] when v? and v.length
        unless @match_hex v
          msg = "bad value[#{i}]"
          break
    throw new Error msg if msg?
    new ChainTail { seqno : val[0], payload_hash : val[1], sig_id : val[2] }

#--------------------------

exports.Leaf = class Leaf

  constructor : ({@pub, @semipriv, @eldest_kid}) ->

  get_public : () -> @pub
  get_semiprivate: () -> @semipriv
  get_eldest_kid : () -> @eldest_kid

  to_json : () ->
    ret = [
      C.versions.leaf.v2,
      (if @pub then @pub.to_json() else []),
      (if @semipriv? then @semipriv.to_json() else []),
      @eldest_kid
    ]
    return ret

  to_string : () -> JSON.stringify(@to_json())

  @parse: ( val) ->
    parser = new Parser val
    err = leaf = null
    try leaf = parser.parse()
    catch e then err = e
    [err, leaf]

  seqno_assertion : () -> (rows) =>
    found = {}

    # Make sure that every sequence found in the DB is also in the LOL
    for {seqno_type, seqno} in rows
      chain_tail = switch seqno_type
        when C.seqno_types.PUBLIC then @pub
        when C.seqno_types.SEMIPRIVATE then @semipriv
        else null
      if not chain_tail? or (chain_tail.seqno isnt seqno) then return false
      found[seqno_type] = true

    # Make sure that every sequence found in the LOL is also in the DB.
    if @semipriv?.seqno and (not found[C.seqno_types.SEMIPRIVATE]) then return false
    if @pub?.seqno and (not found[C.seqno_types.PUBLIC]) then return false

    return true

  seqno_and_prev_assertion : (typ) -> (rows) =>
    chain_tail = switch typ
      when C.seqno_types.PUBLIC then @pub
      when C.seqno_types.SEMIPRIVATE then @semipriv
      else null

    # Case 0 is a null length
    if rows.length is 0
      if chain_tail is null or chain_tail.length is 0 then true
      else false
    else if rows.length is 1 and chain_tail?
      (chain_tail.seqno is rows[0].seqno) and (chain_tail.payload_hash is rows[0].payload_hash )
    else
      false

#===========================================================
