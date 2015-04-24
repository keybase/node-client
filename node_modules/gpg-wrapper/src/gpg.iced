
{colgrep} = require './colgrep'
{E} = require './err'
{parse} = require('pgp-utils').userid
ispawn = require 'iced-spawn'
{make_esc} = require 'iced-error'
spotty = require 'spotty'

##=======================================================================

_gpg_cmd = "gpg"
exports.set_gpg_cmd = set_gpg_cmd = (c) -> _gpg_cmd = c
exports.get_gpg_cmd = ( ) -> _gpg_cmd

# A default log for uncaught stderr
_log = null
exports.set_log = (l) -> _log = l

##=======================================================================

exports.find_and_set_cmd = (cmd, cb) ->
  if cmd?
    await (new GPG { cmd }).test defer err, v
    if err?
      err = new Error "Could not access the supplied GPG command '#{cmd}'"
  else
    cmds = [ "gpg2", "gpg" ]
    for cmd in cmds
      await (new GPG { cmd }).test defer err, v
      break unless err
    if err?
      err = new Error "Could not find GPG command: tried 'gpg2' and 'gpg'"
  set_gpg_cmd(cmd) unless err?
  cb err, v, cmd

##=======================================================================

_tty = null

exports.pinentry_init = (cb) ->
  await spotty.tty defer err, tmp
  _tty = tmp
  cb err, _tty

##=======================================================================

exports.GPG = class GPG

  #----

  constructor : (opts) ->
    @CMD = if (c = opts?.cmd)? then c else _gpg_cmd

  #----

  mutate_args : (args) ->

  #----

  test : (cb) ->
    await ispawn.run { name : @CMD, args : [ "--version" ], quiet : true }, defer err, out
    cb err, out

  #----

  run : (inargs, cb) ->
    stderr = null
    @mutate_args inargs
    env = process.env
    delete env.LANGUAGE
    env.GPG_TTY = _tty if _tty?
    inargs.name = @CMD
    inargs.eklass = E.GpgError
    inargs.opts = { env }
    inargs.log = _log if _log?
    inargs.stderr = stderr = new ispawn.BufferOutStream() if not inargs.stderr? and inargs.quiet
    inargs.args = [ "--no-options"].concat(inargs.args) if inargs.no_options
    await ispawn.run inargs, defer err, out
    if err? and stderr?
      err.stderr = stderr.data()
    cb err, out

  #----

  command_line : (inargs) ->
    @mutate_args inargs
    v = [ @CMD ].concat inargs.args
    v.join(" ")

  #----

  assert_no_collision : (id, cb) ->
    args = [ "-k", "--with-colons", id ]
    n = 0
    await @run { args, quiet : true } , defer err, out
    if err? then # noop
    else
      rows = colgrep {
        patterns : {
          0 : /^[sp]ub$/
          4 : (new RegExp "^.*#{id}$", "i")
        },
        buffer : out,
        separator : /:/
      }
      if (n = rows.length) > 1
        err = new E.PgpIdCollisionError "Found two keys for ID=#{short_id}"
    cb err, n

  #----

  assert_exactly_one : (short_id, cb) ->
    await @assert_no_collision short_id, defer err, n
    err = new E.NotFoundError "Didn't find a key for #{short_id}" unless n is 1
    cb err

##=======================================================================

