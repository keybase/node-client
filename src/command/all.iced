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
db = require '../db'
gpgw = require 'gpg-wrapper'
keyring = require '../keyring'
{platform_info,version_info} = require '../version'
proxyca = require '../proxyca'

##=======================================================================

# This is somewhat of a hack.  Keep track of all of the parsers on our own
# that way we can reference them later for the purposes of helping the user
# with `keybase help id` or something.
exports.SubParserWrapper = class SubParserWrapper

  constructor : (@subparsers) ->
    @_lookup = {}

  addParser : (args...) ->
    @_last_sub = sub = @subparsers.addParser args...

  add_lookup : (names) ->
    for n in names
      @_lookup[n] = @_last_sub
    @_last_sub = null

  lookup : (n) -> @_lookup[n]

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

  lookup_parser : (n) -> @_spw.lookup(n)

  #---------------------------------

  add_subcommands : () ->

    # Add the base options that are useful for all subcommands
    add_option_dict @ap, Base.OPTS

    list = [ 
      "cert"
      "dir"
      "config"
      "decrypt"
      "encrypt"
      "help"
      "id"
      "join"
      "keygen"
      "list_tracking"
      "login"
      "logout"
      "pull"
      "push"
      "prove"
      "reset"
      "revoke"
      "revoke_proof"
      "search"
      "sign"
      "status"
      "switch"
      "track"
      "untrack"
      "update"
      "verify"
      "version"
    ]

    subparsers = @ap.addSubparsers {
      title : 'subcommands'
      dest : 'subcommand_name'
    }

    # A hack for interposing on ArgParser. See above
    # for more details.
    @_spw = new SubParserWrapper subparsers

    @commands = {}

    for m in list
      mod = require "./#{m}"
      obj = new mod.Command @
      names = obj.add_subcommand_parser @_spw
      @_spw.add_lookup names
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
        err = @cmd.set_argv @argv
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
    await @run defer err, rc
    rc = 0 unless rc?
    if err?
      msg = if (err instanceof gpgw.E.GpgError) then "`gpg` exited with code #{err.rc}"
      else err.message
      log.error msg
      log.warn err.stderr.toString('utf8') if err.stderr?
    process.exit if err? then -2 else rc

  #---------------------------------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @setup   esc defer()
    await @cmd.run esc defer rc
    cb null, rc

  #----------------------------------

  config_logger : () ->
    p = log.package()
    if @argv.debug
      p.env().set_level p.DEBUG
    if env().get_no_color()
      p.env().set_use_color false
    gpgw.set_log log.warn

  #----------------------------------

  init_keyring : () ->
    keyring.init()

  #----------------------------------

  load_db : (cb) ->
    err = null
    if @cmd.use_db()
      await db.open defer err
    cb err

  #----------------------------------

  cleanup_previous_crash : (cb) ->
    err = null
    cb err

  #----------------------------------

  startup_message : (cb) ->
    p = log.package()
    log.debug "+ startup message"
    if p.env().get_level() is p.DEBUG
      log.debug "| CLI version: #{(new PackageJson).version()}"
      log.debug "| Platform info: #{JSON.stringify platform_info()}"
      await version_info @_gpg_version, defer err, info
      if err?
        log.error "Error fetching version info: #{err.message}"
      else
        log.debug "| Version info: #{JSON.stringify info}"
    log.debug "- startup message"
    cb null

  #----------------------------------

  init_gpg : (cb) ->
    err = null
    if @cmd.use_gpg() 
      c = env().get_gpg_cmd()
      log.debug "+ testing GPG command-line client #{if c? then c else '<default: gpg>'}"
      await keyring.master_ring().test defer err, @_gpg_version
      log.debug "- tested GPG command-line client -> #{err}"
      if err?
        err = new E.GpgError "Could not acces gpg cmd line client '#{c}'"
      else if c?
        gpgw.set_gpg_cmd c
    cb err

  #----------------------------------

  init_proxy_cas : (cb) ->
    await proxyca.init defer err
    cb err

  #----------------------------------

  setup : (cb) ->
    esc = make_esc cb, "setup"

    init_env()
    await @parse_args esc defer()
    env().set_argv @argv
    @config_logger()
    await @load_config esc defer()
    env().set_config @config
    @init_keyring()
    await @init_gpg esc defer()
    await @init_proxy_cas esc defer()

    await @startup_message esc defer()
    await @load_db esc defer()
    await @cleanup_previous_crash esc defer()
    await @load_session esc defer()
    await @cmd.assertions esc defer()
    env().set_session @session
    cb null

##=======================================================================

exports.run = run = () -> (new Main).main()

##=======================================================================
