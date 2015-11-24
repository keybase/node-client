
{Base} = require './base'
{constants} = require './constants'
{Subkey,SubkeyBase} = require './subkey'

#==========================================================================

exports.Sibkey = class Sibkey extends SubkeyBase

  get_field : () -> "sibkey"
  get_new_key_section : () -> @sibkey
  set_new_key_section : (s) -> @sibkey = s
  get_new_km : () -> @sibkm
  _type : () -> constants.sig_types.sibkey
  need_reverse_sig : () -> true

  _v_include_pgp_details : () -> true
  _required_sections : () -> super().concat(["sibkey"])
  _optional_sections : () -> super().concat(["revoke"])

  constructor : (obj) ->
    @sibkey = obj.sibkey
    @sibkm = obj.sibkm
    super obj

#==========================================================================
