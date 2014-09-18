
urlmod = require 'url'
{Parser} = require './assertion_parser'

#==================================================================

class Expr

  toString : () ->

  match_set : (proof_set) -> false

#==================================================================

class URI extends Expr

  #----------------------------------------

  constructor : ( {@key, @value}) ->

  #----------------------------------------

  keys : () -> [ @key ]

  #----------------------------------------

  check : () ->
    if not @value and @value.length?
      throw new Error "Bad '#{@key}' assertion, no value found"

    throw new Error "Unknown assertion type '#{@key}'" unless @key in [
      'twitter', 'github', 'hackernews', 'reddit', 'keybase', 'coinbase'
    ]

  #----------------------------------------

  @parse : (s) ->
    obj = urlmod.parse(s)

    if (key = obj.protocol)? and key.length
      key = key.toLowerCase()
      key = key[0...-1] if key? and key[-1...] is ':'
    else
      throw new Error "Bad assertion, no 'type' given: #{s}"

    value = value.toLowerCase() if (value = obj.hostname)?

    klasses =
      web : Web
      http : Http
      dns : Host
      https : Host
      fingerprint : Fingerprint

    klass = URI unless (klass = klasses[key])?
    ret = new klass { key, value }
    ret.check()
    return ret

  #----------------------------------------

  toString : () -> "#{@key}://#{@value}"

  #----------------------------------------

  match_set : (proof_set) ->
    proofs = proof_set.get @keys()
    for proof in proofs
      return true if @match_proof(proof)
    return false

  #----------------------------------------

  match_proof : (proof) ->
    (proof.key.toLowerCase() in @keys()) and (@value is proof.value.toLowerCase())

#==================================================================

class Host extends URI
  check : () ->
    if @value.indexOf(".") < 0
      throw new Error "Bad hostname given: #{@value}"

class Web extends Host
  keys : () -> [ 'http', 'https', 'dns' ]

class Http extends Host
  keys : () -> [ 'http', 'https' ]

class Fingerprint extends URI
  match_proof : (proof) ->
    ((@key is proof.key.toLowerCase()) and (@value is proof.value[(-1 * @value.length)...].toLowerCase()))
  check : () ->
    unless @value.match /^[a-fA-F0-9]+$/
      throw new Error "Bad fingerprint given: #{@value}"

#==================================================================

class AND extends Expr

  constructor : (args...) -> @factors = args

  toString : () -> "(" + (f.toString() for f in @factors).join(" && ") + ")"

  match_set : (proof_set) ->
    for f in @factors
      return false unless f.match_set(proof_set)
    return true

#==================================================================

class OR extends Expr

  constructor : (args...) -> @terms = args

  toString : () -> "(" + (t.toString() for t in @terms).join(" || ") + ")"

  match_set : (proof_set) ->
    for t in @terms
      return true if t.match_set(proof_set)
    return false

#==================================================================

exports.Proof = class Proof

  constructor : ({@key, @value}) ->

#-----------------

exports.ProofSet = class ProofSet

  constructor : (@proofs) ->
    @make_index()

  get : (keys) ->
    out = []
    for k in keys when (v = @_index[k])?
      out = out.concat v
    return out

  make_index : () ->
    d = {}
    for proof in @proofs
      v = d[proof.key] = [] unless (v = d[proof.key])?
      v.push proof
    @_index = d

#==================================================================

exports.parse = parse = (s) ->
  parser = new Parser
  parser.yy = { URI, OR, AND }
  return parser.parse(s)

#==================================================================
