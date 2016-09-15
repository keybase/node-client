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
tor = require '../tor'
colors = require '../colors'
{check_node_async} = require 'badnode'
ispawn = require 'iced-spawn'
colors_base = require 'colors'

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
      "btc"
      "cert"
      "dir"
      "config"
      "decrypt"
      "encrypt"
      "help"
      "id"
      "join"
      "keygen"
      "list_signatures"
      "list_tracking"
      "login"
      "logout"
      "pull"
      "push"
      "prove"
      "reset"
      "revoke"
      "revoke_sig"
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
    esc = make_esc cb, "load_config"
    if @cmd.use_config()
      await env().maybe_fallback_to_layout_v1 esc defer res
      if res
        log.debug "| Fallback to layout_v1"
      @config = new Config env().get_config_filename(), @cmd.config_opts()
      await @config.open esc defer()
    cb null

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
      # No need to print error, since it's end of life...
      # log.error msg
      # log.warn err.stderr.toString('utf8') if err.stderr?
    process.exit if err? then -2 else rc

  #---------------------------------

  end_of_life : (cb) ->
    {bold, red} = colors_base
    msg = (m) -> console.error bold red m
    msg "The Keybase Node.js client is no longer supported."
    msg "Please upgrade to our new and improved client via:"
    msg ""
    msg "    https://keybase.io/download"
    msg ""
    msg "To uninstall this now-deprecated client:"
    msg ""
    msg "      npm uninstall -g keybase-installer"
    msg "      npm uninstall -g keybase"
    msg ""
    msg "Thank you!"
    cb new Error "end of the line"

  #---------------------------------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @end_of_life esc defer()
    await @setup   esc defer()
    await @cmd.run esc defer rc
    cb null, rc

  #----------------------------------

  config_logger : () ->
    p = log.package()
    if @argv.debug
      p.env().set_level p.DEBUG
    else if @argv.quiet
      p.env().set_level p.ERROR
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
      log.debug "+ testing GPG command-line client #{if c? then c else '<default: gpg2 or gpg>'}"
      await gpgw.find_and_set_cmd c, defer err, @_gpg_version, cmd
      if err?
        err = new E.GpgError err.message
      else if c?
        log.debug "| Using the supplied GPG cmd: '#{c}'"
      else if not c? and cmd
        log.debug "| using GPG command: #{cmd}"
        env().set_gpg_cmd cmd
      log.debug "- tested GPG command-line client -> #{err}"
      if not err?
        await gpgw.pinentry_init defer e2, tty
        if e2?
          log.debug "Warning on pinentry init: #{e2.toString()}"
        else if tty?
          log.debug "Setting GPG_TTY=#{tty}"
        else
          log.debug "No tty to set"
    cb err

  #----------------------------------

  init_tor : (cb) ->
    err = null
    if tor.enabled()
      px = tor.proxy()
      if @cmd.needs_cookies() and tor.strict()
        err = new E.TorStrictError "Cannot run this command in strict Tor mode"
      else
        log.warn "In Tor mode: strict=#{colors.bold(JSON.stringify !!tor.strict())}; proxy=#{px.hostname}:#{px.port}"
        log.warn "Tor support is in #{colors.bold('alpha')}; please be careful and report any issues"
    cb err

  #----------------------------------

  init_proxy_cas : (cb) ->
    await proxyca.init defer err
    cb err

  #----------------------------------

  setup : (cb) ->
    esc = make_esc cb, "setup"

    # Check that we have a good version of node...
    await check_node_async null, esc defer()

    init_env()
    await @parse_args esc defer()
    env().set_argv @argv
    @config_logger()
    await @load_config esc defer()
    env().set_config @config
    await @init_tor esc defer()
    await @init_gpg esc defer()
    @init_keyring()
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
