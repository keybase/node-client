

{gpg} = require 'gpg-wrapper'
{get_tmp_gpg_sec_keyring,get_tmp_gpg_pub_keyring, get_tmp_gpg_trustdb} = require './env'
{log} = require './log'

#============================================================

exports.gpg = (opts, cb) ->

  if opts.tmp
    log.debug "| Accessing the temporary keychain"
    opts.args = [
        "--no-default-keyring"
        "--keyring"
        get_tmp_gpg_pub_keyring()
        "--secret-keyring"
        get_tmp_gpg_sec_keyring()
        "--trustdb-name"
        get_tmp_gpg_trustdb()
        "--no-random-seed-file"
      ].concat opts.args

  gpg opts, cb

#============================================================
