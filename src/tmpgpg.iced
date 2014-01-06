

{gpg} = require 'gpg-wrapper'
{env} = require './env'
log = require './log'

#============================================================

exports.gpg = (opts, cb) ->

  if opts.tmp
    log.debug "| Accessing the temporary keychain"
    opts.args = [
        "--keyring",            env().get_tmp_gpg_pub_keyring(),
        "--secret-keyring",     env().get_tmp_gpg_sec_keyring(),
        "--trustdb-name",       env().get_tmp_gpg_trustdb()
        "--no-default-keyring",
        "--no-random-seed-file"
      ].concat opts.args

  gpg opts, cb

#============================================================
