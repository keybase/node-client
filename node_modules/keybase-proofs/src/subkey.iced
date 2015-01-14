
{Base} = require './base'
{constants} = require './constants'
{make_esc} = require 'iced-error'
pgp_utils = require('pgp-utils')
{bufeq_secure} = pgp_utils.util

#==========================================================================

exports.SubkeyBase = class SubkeyBase extends Base

  get_subkey : () -> null
  get_subkm : () -> null
  set_subkey : (s) ->
  get_field : () -> null

  _v_generate : (opts, cb) ->
    esc = make_esc cb, "_v_generate"
    if not @get_subkey()? and @get_subkm()?
      reverse_sig = null
      if @get_subkm().get_keypair().can_sign()
        eng = @get_subkm().make_sig_eng()
        msg = @km().get_ekid()
        await eng.box msg, esc defer { armored, type }
        reverse_sig =
          sig : armored
          type : type
      obj =
        kid : @get_subkm().get_ekid().toString('hex')
        reverse_sig: reverse_sig
      @set_subkey obj
      obj.notes = @notes if @notes?
    cb null

  _json : () ->
    ret = super {}
    ret.body[@get_field()] = @get_subkey()
    return ret

  _v_check : ({json}, cb) ->
    esc = make_esc cb, "SubkeyBase::_v_check"
    err = null
    await super { json }, esc defer()
    if (sig = json?.body?[@get_field()]?.reverse_sig?.sig)? and (skm = @get_subkm())?
      eng = skm.make_sig_eng()
      await eng.unbox sig, esc defer payload
      unless bufeq_secure (a = @km().get_ekid()), (b = payload)
        err = new Error "Bad reverse sig payload: #{a.toString('hex')} != #{b.toString('hex')}"
    cb err

  constructor : (obj) ->
    @notes = obj.notes
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
    super obj

#==========================================================================
