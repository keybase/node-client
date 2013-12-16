{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
session = require '../session'
{make_esc} = require 'iced-error'
{prompt_for_int} = require '../prompter'

##=======================================================================

find_fingerprint = (raw) ->
  x = /^pub\s+[0-9]{4}R\/([0-9A-F]{8}) /
  if (m = raw.match x) then m[1] else null

log_10 = (x) ->
  val = 0
  while x > 0
    val++
    x = Math.floor x/10
  return val

pad = (i,places) ->
  n = places - (log_10 i)
  n = 0 if n < 0
  spc(n) + i

spc = (i) -> repeat(' ', i)

repeat = (c,i) -> (c for [0...i]).join('')

##=======================================================================

exports.Command = class Command extends Base

  #----------

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases  : []
      help : "push a PGP key from the client to the server"
    name = "push"
    sub = scp.addParser name, opts
    sub.addArgument [ "search" ], { nargs : '?' }
    return opts.aliases.concat [ name ]

  #----------

  query_keys : (cb) ->
    @keys = null
    args = [ "-k" ] 
    if (v = @argv.search?).length > 0
      args.push (@search = v[0])
    else @search = null
    await gpg { args }, defer err, out
    unless err?
      raw = out.toString().split("\n\n")
      keys = for r in raw when (f = find_fingerprint r)
        { lines : r.split("\n"), fingerprint : f }
    cb err, keys

  #----------

  longest_line : (keys) ->
    longest = 0
    for key in keys
      for line in key.lines
        longest = l if (l = line.length) > longest
    return longest

  #----------

  select_key_menu : (keys) ->
    width = log_10(keys.length + 1)
    longest = @longest_line(keys) + width + 3
    for k,i in keys
      lines = k.lines
      j = i + 1
      console.log "(#{pad(j,width)}) " + lines[0]
      for line in lines[1...]
        console.log spc(width+3) + line
      console.log repeat '~', longest

  #----------

  select_key : (keys, cb) ->
    if @search
      console.log "Multiple keys were found that matched '#{@search}':\n"
    else
      console.log "Multiple keys found:"

    @select_key_menu keys
    console.log ""
    await prompt_for_int 1, keys.length, defer err, sel
    console.log sel
    out = if err? then null else keys[sel-1]
    if out?
      console.log "Picked key: #{out.fingerprint}"
    cb err, out

  #----------

  run : (cb) ->
    esc = make_esc cb, "run"
    await @query_keys esc defer keys
    if keys.length > 1
      await @select_key keys, esc defer key
    else
      key = keys[0]
    await session.login esc defer()
    console.log session.logged_in()
    cb null

##=======================================================================

