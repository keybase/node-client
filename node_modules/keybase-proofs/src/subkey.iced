
{Base} = require './base'
{constants} = require './constants'
{make_esc} = require 'iced-error'
pgp_utils = require('pgp-utils')
{json_stringify_sorted,unix_time,streq_secure} = pgp_utils.util

#==========================================================================

a_json_parse = (x, cb) ->
  ret = err = null
  try ret = JSON.parse x
  catch e then err = e
  cb err, ret

json_cp = (x) -> JSON.parse JSON.stringify x

#==========================================================================

exports.SubkeyBase = class SubkeyBase extends Base

  get_subkey : () -> null
  get_subkm : () -> null
  set_subkey : (s) ->
  get_field : () -> null

  _v_generate : (opts, cb) ->
    esc = make_esc cb, "_v_generate"
    if not @get_subkey()? and @get_subkm()?
      obj =
        kid : @get_subkm().get_ekid().toString('hex')
        reverse_sig: null
      obj.parent_kid = @parent_kid if @parent_kid?
      @set_subkey obj
      if @get_subkm().can_sign()
        msg = @json()
        eng = @get_subkm().make_sig_eng()
        await eng.box msg, esc defer { armored, type }
        obj.reverse_sig = armored
    cb null

  _json : () ->
    ret = super {}
    ret.body[@get_field()] = @get_subkey()
    ret.body.device = @device if @device?
    return ret

  _match_json : (outer, inner) ->
    outer = json_cp outer
    # body.sibkey.reverse_sig should be the only field different between the two
    outer?.body?[@get_field()].reverse_sig = null
    a = json_stringify_sorted outer
    b = json_stringify_sorted inner
    err = null
    unless streq_secure a, b
      err = new Error "Reverse sig json mismatch: #{a} != #{b}"
    return err

  _v_check : ({json}, cb) ->
    esc = make_esc cb, "SubkeyBase::_v_check"
    await super { json }, esc defer()
    await @reverse_sig_check { json, subkm : @get_subkm() }, esc defer()
    cb null

  reverse_sig_check : ({json, subkm}, cb) ->
    esc = make_esc cb, "SubkeyBase::reverse_sig_check"
    err = null
    if (sig = json?.body?[@get_field()]?.reverse_sig)? and subkm?
      eng = subkm.make_sig_eng()
      await eng.unbox sig, esc defer raw
      await a_json_parse raw, esc defer payload
      rsk = subkm.get_ekid().toString('hex')
      if (err = @_match_json json, payload)? then # noop
      else if not streq_secure (a = json?.body?[@get_field()]?.kid), (b = rsk)
        err = new Error "Sibkey KID mismatch: #{a} != #{b}"
      else
        @reverse_sig_kid = rsk
    cb err

  constructor : (obj) ->
    @device = obj.device
    super obj

#==========================================================================

exports.Subkey = class Subkey extends SubkeyBase

  get_field : () -> "subkey"
  get_subkey : () -> @subkey
  get_subkm : () -> @subkm
  set_subkey : (s) -> @subkey = s
  _type : () -> constants.sig_types.subkey

  constructor : (obj) ->
    @subkey = obj.subkey
    @subkm = obj.subkm
    @parent_kid = obj.parent_kid
    super obj

#==========================================================================
