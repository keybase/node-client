{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{E} = require '../err'
{TrackSubSubCommand} = require '../tracksubsub'
{BufferInStream} = require('iced-spawn')
{master_ring} = require '../keyring'
{make_esc} = require 'iced-error'
{dict_union} = require '../util'
{User} = require '../user'
{env} = require '../env'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : dict_union TrackSubSubCommand.OPTS, {
    s:
      alias : "sign"
      action : "storeTrue"
      help : "sign in addition to encrypting"
    m:
      alias : "message"
      help : "provide the message on the command line"
    b :
      alias : 'binary'
      action: "storeTrue"
      help : "output in binary (rather than ASCII/armored)"
    o :
      alias : 'output'
      help : 'the output file to write the encryption to'
  }

  #----------

  add_subcommand_parser : (scp) ->
    opts =
      aliases : [ "enc" ]
      help : "encrypt a message and output to stdout or a file"
    name = "encrypt"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "them" ], { nargs : 1 , help : "the username of the receiver (comma-sep for multiple)" }
    sub.addArgument [ "file" ], { nargs : '?', help : "the file to be encrypted" }
    return opts.aliases.concat [ name ]

  #----------

  do_encrypt : (cb) ->
    args = [
      "--encrypt",
      "--trust-mode", "always"
    ]
    for target in @targets
      for key in target.user.gpg_keys
        args = args.concat "-r", key.fingerprint().toString('hex')
    if @argv.sign
      sign_key = if @targets[0].is_self then @targets[0].user else @targets[0].tssc.me
      args.push( "--sign", "-u", (sign_key.fingerprint true) )
    gargs = { args }
    gargs.quiet = true
    args.push("--output", o, "--yes") if (o = @argv.output)
    args.push "-a"  unless @argv.binary
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message
    else if @argv.file?
      args.push @argv.file
    else
      gargs.stdin = process.stdin
    await master_ring().gpg gargs, defer err, out
    unless @argv.output?
      if @argv.binary
        await process.stdout.write out, defer()
      else
        log.console.log out.toString('utf8')
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    batch = (not @argv.message and not @argv.file?)

    if @argv.sign and not env().is_configured()
      cb new Error "You can't sign messages when you aren't logged in."
      return

    # We tentatively resolve usernames of the form twitter://foo to
    # foo_keybase, but we still need to assert it's the right person
    # later on.
    target_unames = @argv.them[0].split ","
    @targets = []
    for uname, i in target_unames
      target = @targets[i] = uname: uname
      await User.resolve_user_name { username : uname }, esc defer them_un, assertions

      if env().is_me them_un
        target.is_self = true
        await User.load_me { secret : true }, esc defer user
        target.user = user
      else
        target.is_self = false
        target.tssc = new TrackSubSubCommand { args : { them : them_un }, opts : @argv, batch, assertions }
        await target.tssc.pre_encrypt esc defer()
        target.user = target.tssc.them

    await @do_encrypt esc defer()
    cb null

##=======================================================================

