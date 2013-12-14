{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'

##=======================================================================

class Main

  #---------------------------------

  constructor : ->
    @commands = {}
    @pkjson = new PackageJson()

  #---------------------------------

  arg_parse_init : (cb) ->
    err = null
    @ap = new ArgumentParser 
      addHelp : true
      version : @pkjson.version()
      description : 'keybase.io command line client'
      prog : @pkjson.bin()

    if not @add_subcommands()
      err = new E.InitError "cannot initialize subcommands" 
    cb err

  #---------------------------------

  add_subcommands : () ->

    # Add the base options that are useful for all subcommands
    add_option_dict @ap, Base.OPTS

    list = [ 
      "version"
      "join"
    ]

    subparsers = @ap.addSubparsers {
      title : 'subcommands'
      dest : 'subcommand_name'
    }

    @commands = {}

    for m in list
      mod = require "./#{m}"
      obj = new mod.Command()
      names = obj.add_subcommand_parser subparsers
      for n in names
        @commands[n] = obj

    true

  #---------------------------------

  parse_args : (cb) ->
    err = null
    @argv = @ap.parseArgs process.argv[2...]
    cmd = @commands[@argv.subcommand_name]
    if not cmd?
      log.error "Subcommand not found: #{argv.subcommand_name}"
      err = new E.BadArgsError "#{argv.subcommand_name} not found"
    else
      cmd.set_argv @argv
    cb err, cmd

  #---------------------------------

  setup_env : () ->

  #---------------------------------

  run : () ->
    await @_run defer err
    process.exit if err? then -2 else 0

  #---------------------------------

  _run : (cb) ->
    esc = make_esc cb, "_run"
    await @arg_parse_init esc defer()
    await @parse_args esc defer cmd
    await cmd.run defer err
    cb null

##=======================================================================

exports.run = run = () -> (new Main).run()

##=======================================================================
