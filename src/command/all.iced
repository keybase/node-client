{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{env,init_env} = require '../env'
{Config} = require '../config'
req = require '../req'
session = require '../session'

##=======================================================================

class Main

  #---------------------------------

  constructor : ->
    @commands = {}
    @pkjson = new PackageJson()

  #---------------------------------

  arg_parse_init : () ->
    err = null
    @ap = new ArgumentParser 
      addHelp : true
      version : @pkjson.version()
      description : 'keybase.io command line client'
      prog : @pkjson.bin()

    if not @add_subcommands()
      err = new E.InitError "cannot initialize subcommands" 
    return err

  #---------------------------------

  add_subcommands : () ->

    # Add the base options that are useful for all subcommands
    add_option_dict @ap, Base.OPTS

    list = [ 
      "version"
      "join"
      "config"
      "push"
      "prove"
      "verify"
      "revoke"
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
    @cmd = null
    err = @arg_parse_init()
    if not err?
      @argv = @ap.parseArgs process.argv[2...]
      @cmd = @commands[@argv.subcommand_name]
      if not @cmd?
        log.error "Subcommand not found: #{argv.subcommand_name}"
        err = new E.ArgsError "#{argv.subcommand_name} not found"
      else
        @cmd.set_argv @argv
    cb err

  #---------------------------------

  load_config : (cb) ->
    err = null
    if @cmd.use_config()
      @config = new Config env().get_config_filename(), @cmd.config_opts()
      await @config.open defer err
    cb err

  #---------------------------------

  load_session : (cb) ->
    err = null
    if @cmd.use_session()
      await session.load defer err
    cb err

  #---------------------------------

  main : () ->
    await @run defer err
    if err? then log.error err.message
    process.exit if err? then -2 else 0

  #---------------------------------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @setup   esc defer()
    await @cmd.run esc defer()
    cb null

  #----------------------------------

  setup : (cb) ->
    esc = make_esc cb, "setup"
    init_env()
    await @parse_args  esc defer()
    env().set_argv @argv
    await @load_config esc defer()
    env().set_config @config
    await @load_session esc defer()
    env().set_session @session
    cb null

##=======================================================================

exports.run = run = () -> (new Main).main()

##=======================================================================
