{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
session = require '../session'
{make_esc} = require 'iced-error'
{prompt_for_int} = require '../prompter'
log = require '../log'
{key_select} = require '../keyselector'
{KeybasePushProofGen} = require '../sigs'
req = require '../req'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : []
      help : "push a PGP key from the client to the server"
    name = "push"
    sub = scp.addParser name, opts
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
      public_key : @km.key.toString('utf8')
    await req.post { endpoint : "key/add", args }, defer err
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "run"
    await key_select @argv.search, esc defer @km
    await session.login esc defer()
    await @sign esc defer()
    await @push esc defer()
    log.info "success!"
    cb null

##=======================================================================

