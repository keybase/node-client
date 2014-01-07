
{GPG} = require 'gpg-wrapper'
{env} = require './env'
log = require './log'

#============================================================

class TmpGPG extends GPG

  mutate_args : (inargs) -> 
    log.debug "| old args: #{inargs.args.join(' ')}"
    log.debug "| Accessing the temporary keychain"
    inargs.args = [
        "--keyring",            env().get_tmp_gpg_pub_keyring(),
        "--secret-keyring",     env().get_tmp_gpg_sec_keyring(),
        "--trustdb-name",       env().get_tmp_gpg_trustdb()
        "--no-default-keyring",
        "--no-random-seed-file"
      ].concat inargs.args
    log.debug "| new args: #{inargs.args.join(' ')}"

#============================================================

exports.obj = obj = (tmp) ->
  klass = if tmp then TmpGPG else GPG
  new klass()

#------------------------------------

exports.assert_no_collision = ({tmp, short_id}, cb) -> obj(tmp).assert_no_collision(short_id, cb)
exports.assert_exactly_one = ({tmp, short_id}, cb)  -> obj(tmp).assert_exactly_one(short_id, cb)
exports.read_uids_from_key = (args, cb)             -> obj(args.tmp).read_uids_from_key(args, cb)

#------------------------------------

exports.gpg = (inargs, cb) -> 
  log.debug "| Call to gpg: #{JSON.stringify inargs}"
  inargs.quiet = false if inargs.quiet and env().get_debug()
  obj(inargs.tmp).run(inargs, cb)

#====================================================================
