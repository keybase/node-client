
fs = require 'fs'
path = require 'path'
{env} = require './env'
{make_esc} = require 'iced-error'
ca = require './ca'
constants = require './constants'
{mkdir_p} = require('iced-utils').fs
log = require './log'

#=========================================================================

_certs = {}

exports.get_file = (host, cb) ->
  mode = 0o600
  log.debug "+ Get main CA cert (host=#{host})"
  cert = ca.certs[host]
  ret = _certs[host]

  esc = make_esc cb, "mainca.get_file"

  if not ret? and cert?
    fn = path.join env().get_ca_cert_dir(), host
    log.debug "| file in question is '#{fn}'"
    await fs.readFile fn, defer err, buf
    skip = false
    if err?
      log.debug "| no existing cert found (#{err})"
    else
      await fs.stat fn, defer err, stat
      if err? or not stat?
        log.debug "| failed to stat existing cert"
      else if (stat.mode & 0o777) isnt mode
        log.debug "| ignoring existing cert since its permissions are wrong"
      else if cert? and (cert isnt buf.toString('utf8'))
        log.debug "| CA cert ignored, since it's wrong (according to ca.iced)"
      else
        log.debug "| existing CA file checked out"
        skip = true
        ret = fn

    if not skip and cert?
      await mkdir_p path.dirname(fn), 0o700, esc defer()
      log.info "Writing CA certfile to #{fn}"
      await fs.writeFile fn, cert, { mode }, esc defer()
    _certs[host] = ret if ret?

  log.debug "- get main CA cert -> #{ret}"
  cb null, ret

#=========================================================================

