log = require './log'
{gpg} = require './gpg'
{make_esc} = require 'iced-error'
{prompt_for_int} = require './prompter'
{master_ring,load_key} = require './keyring'
{E} = require './err'
{format} = require('pgp-utils').userid
{tablify} = require 'tablify'
{unix_time} = require('iced-utils').util

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
      await load_key { @username, fingerprint : key.fingerprint() }, esc defer km
    else
      err = new E.NoLocalKeyError "No local keys found! Try `keybase gen` to generate one."
    cb err, km

  #----------

  query_keys : (cb) ->
    opts = { @secret, @query }
    await master_ring().index2 opts, defer err, index, warnings
    keys = if err? then null else (key for key in index.keys() when not key.is_revoked())
    cb err, keys

  #----------

  longest_line : (keys) ->
    longest = 0
    for key in keys
      for line in key.lines
        longest = l if (l = line.length) > longest
    return longest

  #----------

  format_ts : (t, zero_val = "n/a") ->
    if t? and t
      d = new Date (t*1000)
      ((""+ s) for s in [ (d.getFullYear()), (d.getMonth()+1), d.getDate() ]).join('-')
    else
      zero_val

  #----------

  key_to_array : (key) ->
    args = [ 
      (key._n_bits + (if key._type is 1 then 'R' else 'D')),
      key.key_id_64(),
      "exp: #{@format_ts(key._expires, 'never')}"
    ].concat key.emails()
    return args

  #----------

  select_key_menu : (keys) ->
    list = []
    for key,i in keys
      list.push( [ "(#{i+1})" ].concat @key_to_array(key) )
    log.console.log tablify list, {
      row_start : ' '
      row_end : ''
      spacer : '  '
      row_sep_char : ''
    }

  #----------

  select_key : (keys, cb) ->
    if @query
      log.console.log "Multiple keys were found that matched '#{@query}':"
    else
      log.console.log "Multiple keys found, please pick one:"
    for key in keys
      key.s = [ key.emails().length, (key._expires or 10e11) ]

    pcmp = (a,b) ->
      ret = if a[0] < b[0] then 1
      else if a[0] > b[0] then -1
      else if a[1] < b[1] then 1
      else if a[1] > b[1] then -1
      else 0
      ret

    keys.sort (a,b) -> pcmp a.s, b.s
    @select_key_menu keys
    prompt = "Pick a key"
    await prompt_for_int { prompt, low : 1, hi : keys.length}, defer err, sel
    out = if err? then null else keys[sel-1]
    if out?
      log.info "Picked key: #{out.key_id_64()}"
    cb err, out

##=======================================================================

exports.key_select = ({username, query, secret}, cb) -> (new KeySelector { username, query, secret }).select cb

##=======================================================================
