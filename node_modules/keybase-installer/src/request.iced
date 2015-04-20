
https = require 'https'
http = require 'http'
{parse} = require 'url'
ProgressBar = require 'progress'
urlmod = require 'url'
request = require 'request'

#========================================================================

class Request

  constructor : ({url, uri, @headers, progress}) ->
    url = url or uri
    @_res = null
    @_data = []
    @_err = null
    @uri = @url = if typeof(url) is 'string' then parse(url) else url
    @_bar = null
    @_opts = { progress }

  #--------------------

  run : (cb) ->
    @_done_cb = cb
    @_launch()

  #--------------------

  _make_opts : () ->
    opts = 
      host : @url.hostname
      port : @url.port or (if @url.protocol is 'https:' then 443 else 80)
      path : @url.path
      method : 'GET'
      headers : @headers

    if (@url.protocol is 'https:') 
      opts.mod = https 
      opts.agent = new https.Agent opts
    else
      opts.mod = http

    opts

  #--------------------

  _launch : () ->
    opts = @_make_opts()
    req = opts.mod.request opts, (res) =>
      if @_opts.progress? and (l = res.headers?["content-length"])? and 
         not(isNaN(l = parseInt(l,10))) and l > @_opts.progress
        @_bar = new ProgressBar "Download #{@url.path} [:bar] :percent :etas (#{l} bytes total)", {
          complete : "=",
          incomplete : ' ',
          width : 50,
          total : l
        }
      @_res = res
      res.request = @
      res.on 'data', (d) => 
        @_data.push d
        @_bar?.tick(d.length)
      res.on 'end',  () => @_finish()
    req.end()
    req.on 'error', (e) => 
      @_err = e
      @_finish()

  #--------------------

  _finish : () ->
    cb = @_done_cb
    @_done_cb = null
    cb @_err, @_res, (Buffer.concat @_data)

#=============================================================================

single = (opts, cb) -> (new Request opts).run cb

#=============================================================================

format_url = (u) -> if (typeof u is 'string') then u else urlmod.format(u)

#-----------

request_progress = (opts, cb) ->
  lim = opts.maxRedirects or 10
  res = body = null
  found = false
  opts.url = parse(opts.url) if typeof(opts.url) is 'string'
  for i in [0...lim] 
    prev_url = opts.url
    await single opts, defer err, res, body
    if err? then break
    else if not (res.statusCode in [301, 302]) 
      found = true
      break
    else if not (url = res.headers?.location)?
      err = new Error "Can't find a location in header for redirect"
      break
    else 
      url = parse(url)
      unless url.host
        url.host = prev_url.host
        url.hostname = prev_url.hostname
        url.port = prev_url.port
        url.protocol = prev_url.protocol
      opts.url = url

  err = if err? then err 
  else if not found then new Error "Too many redirects"
  else if (res.statusCode >= 200 and res.statusCode < 300) then null
  else new Error "In #{format_url opts.url}: HTTP failure, code #{res.statusCode}"

  cb err, res, body

#============================================================================

request_mikeal = (opts, cb) ->
  opts.encoding = null
  rv = new iced.Rendezvous()
  url = opts.url or opts.uri
  url_s = if typeof(url) is 'object' then url.format() else url
  request opts, rv.id(true).defer(err, res, body)

  process.stderr.write("Downloading...")
  loop
    setTimeout rv.id(false).defer(), 100
    await rv.wait defer which 
    if which then break
    process.stderr.write(".")
  process.stderr.write("..done\n") 
  cb err, res, body

#============================================================================

exports.request = (opts, cb) ->
  if opts.proxy? then request_mikeal opts, cb
  else request_progress opts, cb

#============================================================================

