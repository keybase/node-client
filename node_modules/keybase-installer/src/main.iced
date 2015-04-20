{getopt} = require 'iced-utils'
{fullname,bin,version} = require './package'
{make_esc} = require 'iced-error'
{BaseCommand} = require './base'
{Installer} = require './installer'
{keyring} = require 'gpg-wrapper'
{constants} = require './constants'
{hash_json} = require './util'
keyset = require '../json/keyset'
log = require './log'
os = require 'os'
path = require 'path'

##========================================================================

class VersionCommand extends BaseCommand

  run : (cb) ->
    console.log fullname()
    cb null

##========================================================================

class HelpCommand extends BaseCommand

  constructor : (argv, @err = null) ->
    super argv

  run : (cb) ->
    console.log """usage: #{bin()} [-dhjvCS] [-p <install-prefix>] [<keybase-version>]

\tUpgrade or install a version of keybase.  Check signatures with
\tKeybase.io's signing key. You can provide a specific version
\tor by default you'll get the most recent version.

Boolean Flags:

\t-d/--debug              -- Turn on debugging output
\t-h/--help               -- Print the help message and quit
\t-j/--key-json           -- Output the hash of the JSON file of the built-in keyset
\t-v/--version            -- Print the version and quit
\t-C/--skip-cleanup       -- Don't delete temporary files after install
\t-S/--no-https           -- Don't use HTTPS. Safe since we check PGP sigs on everything.
\t-O/--no-gpg-options     -- Turn off GPG options file for temporary keyring operations

Options:

\t-g/--gpg <cmd>
\t\tUse a GPG command other than `gpg`

\t-k/--keyring-dir <dir>
\t\tWhere to store our GPG keys.
\t\t(default: ~/.keybase-installer/keyring)

\t-n/--npm <cmd>
\t\tUse an npm command other than `npm`

\t-p/--prefix <dir>
\t\tInstall to the given prefix
\t\t(rather than where `npm` installs by default)

\t-u/--url-prefix <prfx>
\t\tSpecify a URL prefix for fetching
\t\t(default: #{constants.url_prefix.https})

\t-x/--proxy <url>
\t\tProxy all downloads through the given proxy

Environment Variables:

\thttp_proxy=<full-url> OR https_proxy=<full-url>
\t\tAs --proxy above, proxy all requests through the
\t\tgiven proxy.

\tPREFIX
\t\tAn install prefix

Version: #{version()}

"""

    cb @err

##========================================================================

class KeyJsonCommand extends BaseCommand

  run : (cb) ->
    keyset.self_sig = null
    process.stdout.write hash_json keyset
    cb null

##========================================================================

class Main

  #-----------

  constructor : ->
    @cmd = null

  #-----------

  parse_args : (cb) ->
    err = null
    flags = [
      "d"
      "h"
      "v"
      "j"
      "C"
      "?"
      "S"
      "O"
      "debug"
      "key-json"
      "hash"
      "help"
      "version"
      "skip-cleanup"
      "no-https"
      "no-gpg-options"
    ]
    @argv = getopt process.argv[2...], { flags }
    if @argv.get("v", "version")
      @cmd = new VersionCommand()
    else if @argv.get("h", "?", "help")
      @cmd = new HelpCommand()
    else if @argv.get("j", "key-json")
      @cmd = new KeyJsonCommand @argv
    else if @argv.get().length > 1
      @cmd = new HelpCommand @argv, (new Error "Usage error: only zero or one argument allowed")
    else
      @cmd = new Installer @argv
    cb err

  #-----------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @setup    esc defer()
    log.debug "+ cmd.run #{version()}"
    await @cmd.run  esc defer()
    log.debug "- cmd.run"
    cb null

  #-----------

  main : () ->
    await @run defer err
    if err?
      log.error err.message
      log.warn err.stderr.toString('utf8') if err.stderr?
    process.exit if err? then -2 else 0

  #-----------

  setup_logger : () ->
    p = log.package()
    p.env().set_level p.DEBUG if @argv.get("d", "debug")

  #-----------

  setup : (cb) ->
    esc = make_esc cb, "setup"
    await @parse_args esc defer()
    @setup_logger()
    cb null

##========================================================================

exports.run = run = () -> (new Main).main()

##========================================================================
