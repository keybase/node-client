
http = require 'http'
{env} = require './env'
reqmod = require './req'
log = require './log'
{E} = require './env'
urlmod = require 'url'

#==================================================================

exports.HKPLoopback = class HKPLoopback

  constructor : () ->
    @_srv = http.createServer @serve.bind(@)
    @_port = null
    @_hostname = "127.0.0.1"

  url : () -> "hkp://#{@_hostname}:#{@_port}/"

  listen : (cb) ->
    log.debug "+ HKPLoopback::init; hunt for a port"
    r = env().get_loopback_port_range()
    for p in [r[0]..r[1]]
      await @_srv.listen p, @_hostname, defer err
      unless err?
        log.debug "| found #{p}"
        @_port = p
        break
    err = if @_port? then null else (new E.LoopbackError "no available ports found")
    log.debug "- HKPLoopback::init -> #{err}"
    cb err

  serve : (req, res) ->
    u = req.url
    log.debug "+ Incoming HKP request on loopback :#{@_port}: #{u}"
    inurl = urlmod.parse u
    opts = 
      json : false
      jar : false
      pathname : inurl.pathname
      search : inurl.search
    await reqmod.get opts, defer err, body, gres
    gres.headers['connection'] = 'close'
    res.writeHead gres.statusCode, gres.headers
    res.write gres.body
    log.debug "- Replied to loopback request w/ status=#{gres.statusCode}"
    res.end()

  close : (cb) ->
    if @_srv?
      await @_srv.close defer()
    cb null

#==================================================================

