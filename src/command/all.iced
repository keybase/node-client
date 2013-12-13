{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'

##=======================================================================

class Main

  #---------------------------------

  constructor : ->
    @commands = {}
    @pkjson = new PackageJson()

  #---------------------------------

  init : (cb) ->
    ok = true
    if ok
      @ap = new ArgumentParser 
        addHelp : true
        version : @pkjson.version()
        description : 'keybase.io command line client'
        prog : @pkjson.bin()

      ok = @add_subcommands()
    cb ok

  #---------------------------------

  add_subcommands : () ->

    # Add the base options that are useful for all subcommands
    add_option_dict @ap, Base.OPTS

    list = [ 
      "version"
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

  parse_args : () ->
    argv = @ap.parseArgs process.argv[2...]
    cmd = @commands[argv.subcommand_name]
    if not cmd?
      log.error "Subcommand not found: #{argv.subcommand_name}"
    else
      cmd.set_argv argv
    cmd

  #---------------------------------

  run : () ->
    await @init defer ok
    cmd = @parse_args() if ok
    await cmd.run defer ok if cmd?
    process.exit if ok then 0 else -2

##=======================================================================

exports.run = run = () -> (new Main).run()

##=======================================================================
