
{BaseCommand} = require './base'
{find_and_set_cmd,keyring,GPG} = require 'gpg-wrapper'
{chain,make_esc} = require 'iced-error'
request = require './request'
{fullname} = require './package'
{constants} = require './constants'
{KeySetup} = require './key_setup'
{KeyUpgrade} = require './key_upgrade'
{GetIndex} = require './get_index'
{SoftwareUpgrade} = require './software_upgrade'
log = require './log'
npm = require './npm'
{mkdir_p} = require('iced-utils').fs
path = require 'path'
colors = require 'colors'
{check_node_async} = require 'badnode'

##========================================================================

exports.Installer = class Installer extends BaseCommand

  constructor : (argv) ->
    super argv

  #------------

  cleanup : (cb) ->
    await @config.cleanup defer e2
    log.error "In cleanup: #{e2}" if e2?
    if not err? and @package?
      log.info "Succesful install: #{@package.filename()}"
    cb()

  #------------

  make_install_dir : (cb) ->
    err = null
    if (p = @config.install_prefix())? and p.length
      await mkdir_p p, 0o755, defer err, made
      if not err? and made
        log.warn "Created install directory: #{p}"
    cb err

  #------------

  test_gpg : (cb) ->
    alt = @config.set_alt_gpg()
    log.debug "+ Installer::test_gpg"
    await find_and_set_cmd alt, defer err, version, cmd
    if err?
      lines = []
      if alt?
        lines.push """
The GPG command you specified `#{alt}` wasn't found; see this page for help installing `gpg`:
"""
      else
        lines.push """
The commands `gpg2` and `gpg` weren't found; you need to install it. See this page for more info:
"""
      lines.push """
\t   https://keybase.io/docs/command_line/prerequisites
"""
      err = new Error lines.join("\n")
    else
      log.debug "| Found '#{cmd}' @ #{version}"
    log.debug "- Installer::test_gpg -> #{if err? then 'FAILED' else 'OK'}"
    cb err

  #------------

  test_npm : (cb) ->
    cmd = @config.get_cmd('npm')
    log.debug "+ Installer::test_npm"
    await npm.check defer err
    if not err? then #noop
    else if (c = @config.get_alt_cmd('npm'))?
      err = new Error "The npm command you specified `#{c}` wasn't found"
    else
      err = new Error "Couldn't find an `npm` command in your path"
    log.debug "- Installer::test_npm -> #{if err? then 'FAILED' else 'OK'}"
    cb err

  #------------

  test_npm_install : (cb) ->
    await npm.test_install defer err, @_install_prefix
    cb err

  #------------

  welcome_message : (cb) ->
    dir = path.join @_install_prefix, "bin"
    cmd = path.join dir, "keybase"
    console.log """
=====================================================================

Welcome to keybase.io!

You have successfully installed the command-line client to

====>    #{colors.bold cmd}    <=======

Please make sure #{colors.bold dir} is in your PATH.

If you're new to the service run:

     $ keybase signup        # signup for a new account
     $ keybase push          # to push your public key to the server
         -- or --
     $ keybase gen           # generate a new key and push it

If you already signed up via the Web or another keybase client, try:

     $ keybase login         # establish a session with the server, and pull down keys

Once you're configured, you can:

     $ keybase prove twitter # prove your twitter identity
     $ keybase id max        # to identify a friend
     $ keybase track max     # to track them and write a proof to the server

And then attempt crypto actions like enc/dec/verify/sign.  See `keybase --help` for
more details.

"""
    cb null

  #------------

  run : (cb) ->
    log.debug "+ Installer::run"
    cb = chain cb, @cleanup.bind(@)
    esc = make_esc cb, "Installer::run"

    await check_node_async null, esc defer()
    await @test_gpg              esc defer()

    @config.set_alt_npm()
    npm.set_config @config

    await @make_install_dir      esc defer()
    await @test_npm              esc defer()
    await @test_npm_install      esc defer()

    @config.set_actual_prefix @_install_prefix

    await @config.make_tmpdir    esc defer()
    await @config.init_keyring   esc defer()
    await @key_setup             esc defer()
    await @get_index             esc defer()
    await @key_upgrade           esc defer()
    await @software_upgrade      esc defer()
    await @welcome_message       esc defer()
    log.debug "- Installer::run"
    cb null

  #------------

  key_setup        : (cb) -> (new KeySetup @config).run cb
  get_index        : (cb) -> (new GetIndex @config).run cb
  key_upgrade      : (cb) -> (new KeyUpgrade @config).run cb
  software_upgrade : (cb) -> (new SoftwareUpgrade @config).run cb

##========================================================================

