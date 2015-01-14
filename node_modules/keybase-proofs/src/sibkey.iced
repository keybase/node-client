
{Base} = require './base'
{constants} = require './constants'
{SubkeyBase} = require './subkey'

#==========================================================================

exports.Sibkey = class Sibkey extends SubkeyBase

  get_field : () -> "sibkey"
  get_subkey : () -> @sibkey
  get_subkm : () -> @sibkm
  set_subkey : (s) -> @sibkey = s
  _type : () -> constants.sig_types.sibkey

  constructor : (obj) ->
    @sibkey = obj.sibkey
    @sibkm = obj.sibkm
    super obj

#==========================================================================
