
{GPG} = require 'gpg-wrapper'
{env} = require './env'
log = require './log'
util = require 'util'
{E} = require './err'

#============================================================

exports.gpg = (inargs, cb) -> 
  log.debug "| Call to gpg: #{util.inspect(inargs)}"
  inargs.quiet = false if inargs.quiet and env().get_debug()
  gpg = new GPG
  await gpg.run inargs, defer err, out
  cb err, out

#====================================================================

exports.StatusParser = class StatusParser

  constructor : () ->
    @_all = []
    @_table = []

  parse : ({buf}) ->
    lines = buf.toString('utf8').split /\r?\n/
    for line in lines
      words = line.split /\s+/
      if words[0] is '[GNUPG:]'
        @_all.push words[1...]
        @_table[words[1]] = words[2...]
    @

  lookup : (key) -> @_table[key]

#====================================================================

exports.parse_signature = (buf) ->
  status_parser = (new StatusParser()).parse {buf}
  err = key = timestamp = null
  d = null
  if not (validsig = status_parser.lookup "VALIDSIG")? 
    err = new E.NotFoundError "no valid signature found"
  else if validsig.length < 9 or isNaN(d = parseInt(validsig[2]))
    err = new E.VerifyError "didn't find a valid signature"
  else
    if validsig.length is 10
      key = 
        primary : validsig[9]
        subkey  : validsig[0]
    else
      key = { primary : validsig[0] }
    timestamp = new Date d*1000
  [err, key, timestamp]

#====================================================================
