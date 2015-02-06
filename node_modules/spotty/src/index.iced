
fs = require 'fs'
tty = require 'tty'
path = require 'path'
{make_esc} = require 'iced-error'

#=======================================================

stateq = (s1, s2) ->
  for f in [ 'dev', 'rdev', 'ino' ]
    return false unless s1[f] is s2[f]
  return true

#=======================================================

class TtyLookup 

  constructor : ({@fd}) ->
    @fd or= 0

  #-------------

  assert_tty : (cb) ->
    err = null
    if not tty.isatty @fd
      err = new Error "stdin is not a tty"
    cb err

  #-------------

  os_check : (cb) ->
    err = null
    unless process.platform in [ 'darwin', 'linux' ]
      err = new Error "can only run on Linux and OSX"
    cb err

    #-------------

  find_tty_in : ({dir, regex}, cb) ->
    ret = null
    esc = make_esc cb, "find_tty_in"
    await fs.readdir dir, esc defer files
    for file in files
      if file.match regex
        await @try_file {dir, file}, defer err, ret
        break if ret?
    cb null, ret

  #-------------

  try_file : ({dir, file}, cb) ->
    p = path.join dir, file
    ret = null
    await fs.stat p, defer err, stat
    ret = p if not err? and stateq stat, @_stat
    cb err, ret

  #-------------

  find_tty : (cb) ->
    await @find_tty_in { dir : "/dev", regex : /^tty[A-Za-z0-9]+$/ }, defer err, res
    unless res?
      await @find_tty_in { dir : "/dev/pts", regex : /^[0-9]+$/   }, defer err, res
    cb err, res

  #-------------

  stat_fd : (cb) ->
    await fs.fstat @fd, defer err, @_stat
    cb err

  #-------------

  run : (cb) ->
    esc = make_esc cb, "TtyLookup.run"
    await @assert_tty esc defer()
    await @os_check esc defer()
    await @stat_fd esc defer()
    await @find_tty esc defer res
    cb null, res

#=======================================================

exports.tty = (cb) -> (new TtyLookup {}).run cb

#=======================================================

