{env} = require './env'
fs = require 'fs'
{make_esc} = require 'iced-error'
{E} = require './err'
log = require './log'

#=========================================================================

class ProxyCACert

  constructor : (@file) ->

  open : (cb) ->
    log.debug "| Load proxy CA: #{@file}"
    await fs.readFile @file, defer err, @raw
    cb err

  to_string : () -> @raw?.toString('utf8')

#=========================================================================

exports.ProxyCACerts = class ProxyCACerts

  constructor : () ->
    @_cas = []
    @_arr = []
    @_files = []

  #--------------------

  read_env : (cb) ->
    o = env().get_proxy_ca_certs()
    v = null
    err = null
    if not o? then # noop
    else if typeof(o) is 'string' then v = [ o ]
    else if typeof(o) is 'object' and Array.isArray(o) then v = o
    else
      err = new E.ArgsError "given CA list can't be parsed as list of files"
    if v?
      # Split each of the elements on ':' character
      # Then join all arrays into one array
      @_files = [].concat (e.split /:/ for e in v)...
    cb err

  #--------------------

  open_files : (cb) ->
    esc = make_esc cb, "CAs::open_files"
    @_cas = (new ProxyCACert(f) for f in @_files)
    for ca in @_cas
      await ca.open esc defer()
    cb null

  #--------------------

  load : (cb) ->
    log.debug "+ Load proxy CAs"
    esc = make_esc cb, "CAs::init"
    await @read_env esc defer()
    await @open_files esc defer()
    @_ca_arr = (c.to_string() for c in @_cas)
    log.debug "- Loaded proxy CAs"
    cb null, (@_cas.length > 0)

  #--------------------

  data : () -> @_ca_arr
  files : () -> @_files

#=========================================================================

_pcc = null
exports.init = (cb) ->
  pcc = new ProxyCACerts()
  await pcc.load defer err, found
  if found and not err?
    _pcc = pcc
  cb err, _pcc

#--------------

exports.get = () -> _pcc

#=========================================================================

