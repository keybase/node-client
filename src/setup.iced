
{env} = require './env'
{db} = require './db'
{session} = require './session'
{make_esc} = require 'iced-error'

#============================================================

#
# Reset a local configuration, which will do three things:
#   1. Nuke the local SQLITE3 cache database
#   2. remove the session.json file
#   3. Remove the `user` stanza from the config file
#
# Note that there is no prompting for this, we just do it.
# If you want to build in seat belts, you need to do so before
# you call us.
#
exports.reset = ({new_username}, cb) ->
  esc = make_esc cb, "setup.reset"
  await session.logout esc defer()
  await db.unlink esc defer()
  c = env().config
  c.set 'user', null
  c.set 'user.name', new_username if new_username?
  await c.write esc defer()
  cb null

#============================================================
