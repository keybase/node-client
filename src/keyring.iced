
{db} = require './db'
{gpg} = require './gpg'
log = require './log'
{constants} = require './constants'
{make_esc} = require 'iced-error'

##=======================================================================

exports.clean_key_imports = (cb) ->
  esc = make_esc cb, "clean_key_imports"
  log.debug "+ clean key imports"
  state = constants.import_state.TEMPORARY
  await db.select_key_imports_by_state state, esc defer keys
  log.debug "| queried for temp keys, got: #{JSON.stringify keys}"
  args = [ "--batch", "--delete-keys" ].concat keys
  await gpg { args }, defer err
  state = constants.import_state.CANCELED
  await db.batch_update_key_import { fingerprints : keys, state }, esc defer()
  log.debug "- clean key imports"
  cb null

##=======================================================================


