{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
session = require '../session'
{make_esc} = require 'iced-error'
{prompt_for_int} = require '../prompter'
log = require '../log'
{key_select} = require '../keyselector'
{KeybasePushProofGen} = require '../sigs'
req = require '../req'
{env} = require '../env'
{prompt_passphrase} = require '../prompter'
{KeyManager} = require '../keymanager'
{E} = require '../err'
{athrow} = require('iced-utils').util

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    g :
      alias : "gen"
      action : "storeTrue"
      help : "generate a new key"

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : []
      help : "push a PGP key from the client to the server"
    name = "push"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "search" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  sign : (cb) ->
    eng = new KeybasePushProofGen { @km }
    await eng.run defer err, @sig
    cb err

  #----------

  push : (cb) ->
    args = 
      is_primary : 1
      sig : @sig.pgp
      sig_id_base : @sig.id
      sig_id_short : @sig.short_id
      public_key : @km.key_data().toString('utf8')
    await req.post { endpoint : "key/add", args }, defer err
    cb err

  #----------

  prompt_passphrase : (cb) ->
    args = 
      prompt : "Your key passphrase (can be the same as your login passphrase)"
      confirm : prompt: "Repeat to confirm"
    await prompt_passphrase args, defer err, pp
    cb null, pp

  #----------

  do_key_gen : (cb) ->
    esc = make_esc cb, "do_key_gen"
    if @argv.search?
      athrow (new E.ArgsError "Cannot provide a search query with then --gen flag"), esc defer()
    await @prompt_passphrase esc defer passphrase 
    log.debug "+ generating public/private keypair"
    await KeyManager.generate { passphrase }, esc defer km_tmp
    log.debug "- generated"
    cb null, km_tmp.key

  #----------

  run : (cb) ->
    esc = make_esc cb, "run"
    if @argv.gen
      await @do_key_gen esc defer @km
    else
      await key_select {username: env().get_username(), query : @argv.search }, esc defer @km
    await session.login esc defer()
    await @sign esc defer()
    await @push esc defer()
    log.info "success!"
    cb null

##=======================================================================

