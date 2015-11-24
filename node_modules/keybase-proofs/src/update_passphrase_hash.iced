
{Base} = require './base'
{constants} = require './constants'

#==========================================================================

exports.UpdatePassphraseHash = class UpdatePassphraseHash extends Base

  constructor : (obj) ->
    @update_passphrase_hash = obj.update_passphrase_hash
    super obj

  _type : () -> constants.sig_types.update_passphrase_hash

  _required_sections : () -> super().concat(["update_passphrase_hash"])

  _v_customize_json : (ret) ->
    ret.body.update_passphrase_hash = @update_passphrase_hash

  _json : -> super { expire_in : 24*60*60 }

#==========================================================================
