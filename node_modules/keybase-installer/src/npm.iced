{run} = require 'iced-spawn'
{exec} = require 'child_process'
path = require 'path'
fs = require 'fs'
log = require './log'
{prng} = require 'crypto'
{strip} = require './util'
os = require 'os'

##-----------------------------------

_config = null

##-----------------------------------

exports.set_config = (c) -> _config = c

##-----------------------------------

exports.npm = npm = ({args}, cb) ->
  name = _config.get_cmd 'npm'
  p = _config.install_prefix()
  args = [ "--prefix", p ].concat(args) if p? and p.length
  await run { args, name }, defer err, out
  cb err, out

##-----------------------------------

exports.check = check_cmd = (cb) ->
  await npm { args : [ "--version" ] }, defer err
  cb err

##-----------------------------------

exports.test_install = (cb) ->
  log.debug "+ Installer::test_npm_install"
  dirname = null

  await @npm { args : [ "get", "prefix" ] }, defer err, out
  if err?
    log.error "Failed to get a prefix from npm"
  else
    dirname = strip out.toString('utf8')
    log.debug "| Testing install directory: #{dirname}"
    r = prng(10).toString('hex')
    test = path.resolve(dirname, ".keybase_test_install_#{r}")
    log.debug "| Writing temporary file, to see if install will work: #{test}"
    await fs.writeFile test, (new Buffer []), { mode : 0o600 }, defer err
    if err?
      if err.code in [ 'EACCES', 'EPERM' ]
        if os.platform() is 'win32' # this is actually any version of windows
          err = new Error "Permission denied - Node was installed as Admin.\n" +
            "\nWindows solution: launch another command window by right-clicking" +
            "\nand selecting \"Run as Administrator\"," +
            "\nthen run `keybase-installer`. (Then you may close the window.)\n"
        else
          err = new Error "Permission denied installing to #{dirname}: try running `sudo keybase-installer` or use the `--prefix` option to install locally"
      else
        err = new Error "Can't write to directory #{dirname}: #{err.code}"
    else
      await fs.unlink test, defer tmp
      if tmp?
        log.warn "Failed to unlink temporary file: #{test}"
      else
        log.debug "| Unlinking file: #{test}"
  log.debug "- Installer::test_npm_install"
  cb err, dirname

##-----------------------------------
