
pgpu = require('pgp-utils').userid
{Warnings} = require('iced-utils').util
util = require 'util'

#==========================================================

class BucketDict

  constructor : () ->
    @_d = {}

  add : (k,v) ->
    k = ("" + k).toLowerCase()
    @_d[k] = b = [] unless (b = @_d[k])?
    b.push v

  get : (k) -> @_d[("" + k).toLowerCase()] or []

  get_0_or_1 : (k) ->
    l = @get(k)
    err = obj = null
    if (n = l.length) > 1
      err = new Error "wanted a unique lookup, but got #{n} object for key #{k}"
    else
      obj = if n is 0 then null else l[0]
    return [err,obj]

#==========================================================

uniquify = (v) ->
  h = {}
  (h[e] = true for e in v)
  (k for k of h)

#==========================================================

class Index

  constructor : () ->
    @_keys = []
    @_lookup =
      email : new BucketDict()
      fingerprint : new BucketDict()
      key_id_64 : new BucketDict()

  push_element : (el) ->
    if (k = el.to_key()) then @index_key k

  index_key : (k) ->
    @_keys.push k
    @_lookup.fingerprint.add(k.fingerprint(), k)
    for e in uniquify(k.emails())
      @_lookup.email.add(e, k)
    for i in k.all_key_id_64s()
      @_lookup.key_id_64.add(i, k)

  lookup : () -> @_lookup
  keys : () -> @_keys
  fingerprints : () -> (k.fingerprint() for k in @keys())

#==========================================================

class Element
  constructor : () ->
    @_err = null
  err : () -> @_err
  is_ok : () -> not @_err?
  to_key : () -> null

#==========================================================

parse_int = (s) -> if s?.match /^[0-9]+$/ then parseInt(s, 10) else s

#==========================================================

class BaseKey extends Element

  constructor : (line) ->
    super()
    if line.v.length < 12
      @_err = new Error "Key is malformed; needs at least 12 fields"
    else
      v = (parse_int(e) for e in line.v)
      [ @_pub, @_trust, @_n_bits, @_type, @_key_id_64, @_created, @_expires ] = v

  err : () -> @_err
  to_key : () -> null
  key_id_64 : () -> @_key_id_64
  fingerprint : () -> @_fingerprint
  add_fingerprint : (line) -> @_fingerprint = line.get(9)
  is_revoked : () -> @_trust is 'r'
  to_dict : ({secret}) -> {
    fingerprint : @fingerprint(),
    key_id_64 : @key_id_64(),
    secret : secret,
    is_revoked : @is_revoked()
  }

#==========================================================

class Subkey extends BaseKey


#==========================================================

class Key extends BaseKey

  constructor : (line) ->
    super line
    @_userids = []
    @_subkeys = []
    @_top = @
    if @is_ok()
      @add_uid line

  emails : () -> (e for u in @_userids when (e = u.email)? )
  to_key : () -> @
  userids : () -> @_userids
  subkeys : () -> @_subkeys

  to_dict : (d) ->
    r = super d
    r.uid = @userids()[0]
    r.all_uids = @userids
    return r

  all_keys : () -> [ @ ].concat(@_subkeys)

  all_key_id_64s : () ->
    ret = (i for s in @all_keys() when (i = s.key_id_64())?)
    return ret

  add_line : (line) ->
    err = null
    if (n = line.v.length) < 2
      line.warn "got too few fields (#{n})"
    else
      switch (f = line.v[0])
        when 'fpr' then @_top.add_fingerprint line
        when 'uid' then @add_uid line
        when 'uat' then # skip user attributes
        when 'sub', 'ssb' then @add_subkey line
        else
          line.warn "unexpected subfield: #{f}"

  add_subkey : (line) ->
    key = new Subkey line
    if key.is_ok()
      @_subkeys.push key
      @_top = key
    else
      line.warn "Bad subkey: #{key.err().message}"

  add_uid : (line) ->
    if (e = line.get(9))? and (u = pgpu.parse(e))?
      @_userids.push u

#==========================================================

class Ignored extends Element

  constructor : (line) ->

#==========================================================

class Line
  constructor : (txt, @number, @parser) ->
    @v = txt.split(":")
    if @v.length < 2
      @warn "Bad line; expectect at least 2 fields"
  warn : (m) -> @parser.warn(@number + ": " + m)
  get : (n) ->
    if (n < @v.length and @v[n].length) then @v[n] else null

#==========================================================

exports.Parser = class Parser

  #-----------------------

  constructor : (@txt) ->
    @_warnings = new Warnings()
    @init()

  #-----------------------

  warn : (w) -> @_warnings.push w
  warnings : () -> @_warnings

  #-----------------------

  init : () -> @lines = (new Line(l,i+1,@) for l,i in @txt.split(/\r?\n/) when l.length > 0)
  peek : () -> if @is_eof() then null else @lines[0]
  get : () -> if @is_eof() then null else @lines.shift()
  is_eof : () -> (@lines.length is 0)

  #-----------------------

  parse_ignored : (line) -> return new Ignored line

  #-----------------------

  parse : () ->
    index = new Index()
    until @is_eof()
      index.push_element(element) if (element = @parse_element()) and element.is_ok()
    return index

  #-----------------------

  is_new_key : (line) -> line? and (line.get(0) in ['pub', 'sec'])

  #-----------------------

  parse_element : () ->
    line = @get()
    if @is_new_key(line) then @parse_key line
    else @parse_ignored line

  #-----------------------

  parse_key : (first_line) ->
    key = new Key first_line
    while (nxt = @peek())? and not(@is_new_key(nxt))
      @get()
      key.add_line(nxt)
    return key

#==========================================================

exports.parse = parse = (txt) -> (new Parser(txt).parse())
exports.list_fingerprints = list_fingerprints = (txt) -> parse(txt).fingerprints()

#==========================================================

