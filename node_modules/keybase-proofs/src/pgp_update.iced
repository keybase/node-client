{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.PGPUpdate = class PGPUpdate extends Base

  _required_sections : () -> super().concat ['pgp_update']

  _v_include_pgp_details : () -> true
  _v_require_pgp_details : () -> true
  _v_pgp_details_dest : (body) -> body.pgp_update
  _v_pgp_km : () -> @pgpkm

  _v_customize_json: (ret) ->
    ret.body.pgp_update =
      kid: @pgpkm.get_ekid().toString 'hex'

  _type : () -> constants.sig_types.pgp_update

  constructor : ({@pgpkm}) -> super
