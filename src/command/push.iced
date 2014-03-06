pg = require './push_and_keygen'
{E} = require '../err'
{make_esc} = require 'iced-error'
{add_option_dict} = require './argparse'
{env} = require '../env'
{key_select} = require '../keyselector'
{load_key} = require '../keyring'
{KeyPatcher} = require '../keypatch'

##=======================================================================

exports.Command = class Command extends pg.Command

  OPTS :
    g :
      alias : "gen"
      action : "storeTrue"
      help : "generate a new key"
    p : 
      alias : "show-public-only-keys"
      action : "storeTrue"
      help : "Allow picking of public keys for which no secret key is available (not recommended)"
    "skip-add-email" :
      action : "storeTrue"
      help : "Skip the prompt asking if we want to store email to key; don't do it"
    "add-email"  :
      action : "storeTrue"
      help : "Add email to key by default, if needed"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : []
      help : "push a PGP key from the client to the server"
    name = "push"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    add_option_dict sub, pg.Command.OPTS
    sub.addArgument [ "search" ], { nargs : '?' , help : "search parameter to find the right key" }
    return opts.aliases.concat [ name ]

  #----------

  check_args : (cb) ->
    err = null
    if @argv.search and @argv.gen
      err = new E.ArgsError "Can't both search and generate; pick one or the other!"
    else if @argv.search and @secret_only()
      err = new E.ArgsError "Can't specify a search with secret-only-push; has to correspond to your public"
    cb err

  #----------

  load_key : (cb) ->
    cb err

  #----------

  prepare_key : (cb) ->
    err = null
    esc = make_esc cb, "Command::prepare_key"
    if @argv.gen
      # On success, will set @key appropriately, so no need to set it ourselves.
      await @do_key_gen esc defer()
    else if @secret_only()
      await load_key { username : env().get_username(), fingerprint : @me.fingerprint() }, esc defer @key
    else
      secret = true unless @argv.show_public_only_keys
      await key_select {username: env().get_username(), query : @argv.search, secret }, esc defer @key
      kp = new KeyPatcher { @key, opts : @argv }
      await kp.run { interactive : true }, esc defer did_patch
      @key = kp.get_key() if did_patch
    cb err

##=======================================================================

