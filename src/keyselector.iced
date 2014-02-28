log = require './log'
{gpg} = require './gpg'
{make_esc} = require 'iced-error'
{prompt_for_int} = require './prompter'
{master_ring,load_key} = require './keyring'
{E} = require './err'

##=======================================================================

find_key_id_64 = (raw) ->
  x = /^(?:pub|sec)\s+[0-9]{4}(?:R|D)\/([0-9A-F]{16}) /
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

exports.KeySelector = class KeySelector

  constructor : ({@username, @query, @secret}) ->

  #----------

  select : (cb) ->
    esc = make_esc cb, "KeySelector::select"
    await @query_keys esc defer keys
    if keys.length > 1
      await @select_key keys, esc defer key
    else if keys.length is 1
      key = keys[0]
    else
      key = null
    err = null
    if key?
      await load_key { @username, key_id_64 : key.ki64 }, esc defer km
    else
      err = new E.NoLocalKeyError "No local keys found! Try `keybase gen` to generate one."
    cb err, km

  #----------

  query_keys : (cb) ->
    @keys = null
    k = if @secret then "-K" else "-k"
    args = [ k, "--keyid-format", "long" ] 
    args.push @query if @query
    await master_ring().gpg { args }, defer err, out
    unless err?
      raw = out.toString().split("\n\n")
      keys = for r in raw when (f = find_key_id_64 r)
        { lines : r.split("\n"), ki64 : f }
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
    sep = () ->
      console.log "\n" + (repeat '~', longest) + "\n"
    sep()
    for k,i in keys
      lines = k.lines
      j = i + 1
      console.log "(#{pad(j,width)}) " + lines[0]
      for line in lines[1...]
        console.log spc(width+3) + line
      sep()

  #----------

  select_key : (keys, cb) ->
    if @query
      console.log "Multiple keys were found that matched '#{@query}':"
    else
      console.log "Multiple keys found, please pick one:"
    @select_key_menu keys
    await prompt_for_int 1, keys.length, defer err, sel
    out = if err? then null else keys[sel-1]
    if out?
      log.info "Picked key: #{out.ki64}"
    cb err, out

##=======================================================================

exports.key_select = ({username, query, secret}, cb) -> (new KeySelector { username, query, secret }).select cb

##=======================================================================
