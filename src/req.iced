request = require 'request'
{env} = require './env'
urlmod = require 'url'
{E} = require './err'
log = require './log'
{certs} = require './ca'
{PackageJson} = require './package'
proxyca = require './proxyca'
tor = require './tor'

#=================================================

m = (dict, method) ->
  dict.method = method
  dict

#=================================================

dcopy = (d) ->
  out = {}
  for k,v of d
    out[k] = v
  return out

#=================================================

exports.Client = class Client

  constructor : (@headers) ->
    @_cookies = {}
    @_session = null
    @_csrf = null
    @_warned = false

  #--------------

  set_headers : (h) -> @headers = h
  get_headers : ()  -> @headers
  add_headers : (d) ->
    @headers or= {}
    (@headers[k] = v for k,v of d)
    true

  #-----------------

  set_session : (s) ->
    unless tor.strict()
      @add_headers { "X-Keybase-Session" : s }
      @_session = s

  #-----------------

  clear_session : () ->
    @_session = null
    delete @headers['X-Keybase-Session'] if @headers?

  #-----------------

  clear_csrf : () ->
    @_csrf = null
    delete @headers['X-CSRF-Token'] if @headers?

  #-----------------

  set_csrf : (c) ->
    unless tor.strict()
      @add_headers { "X-CSRF-Token" : c }
      @_csrf = c

  #-----------------

  get_session : () -> @_session
  get_csrf : () -> @_csrf

  #-----------------

  _find_cookies : (res) ->
    if (v = res.headers?['set-cookie'])?
      for cookie_line in v
        parts = cookie_line.split "; "
        if parts.length
          [name,val] = parts[0].split "="
          @_cookies[name] = decodeURIComponent val

  #-----------------

  error_for_humans : ({err, uri, uri_fields}) ->
    host = uri_fields.hostname
    port = uri_fields.port
    switch err.code
      when 'ENOTFOUND'
        new E.ReqNotFoundError "Host '#{host}' wasn't found in DNS; check your network"
      when 'ECONNREFUSED'
        new E.ReqConnRefusedError "Host '#{host}:#{port}' refused connection; maybe the server is down"
      else
        new E.ReqGenericError "Could not access URL: #{uri}"

  #-----------------

  req : ({method, endpoint, args, http_status, kb_status, pathname, search, json, jar, need_cookie}, cb) ->
    method or= 'GET'

    tha = null
    if (tor_on = tor.enabled())
      tha = tor.hidden_address()
      log.debug "| Using tor hidden address: #{JSON.stringify tha}"

    if not(jar?) and not(tor.strict()) and (need_cookie or not tor_on)
      jar = true

    json = true unless json?
    opts = { method, json }
    opts.jar = jar if jar?

    opts.headers = if @headers? then dcopy(@headers) else {}
    pjs = new PackageJson
    opts.headers["X-Keybase-Client"] = pjs.identify_as()
    opts.headers["User-Agent"] = pjs.user_agent()

    kb_status or= [ "OK" ]
    http_status or= [ 200 ]

    tls = not(tor_on) and not(env().get_no_tls())

    uri_fields = {
      protocol : "http#{if tls then 's' else ''}"
      hostname : if tor_on then tha.hostname else env().get_host()
      port : if tor_on then tha.port else env().get_port()
      pathname : pathname or [ env().get_api_uri_prefix(), (endpoint + ".json") ].join("/")
      search : search
    }
    uri_fields.query = args if method in [ 'GET', 'DELETE' ]
    opts.uri = urlmod.format uri_fields
    if method is 'POST'
      opts.body = args

    log.debug "+ request to #{endpoint} (#{opts.uri}) (cookie=#{!!jar})"

    if (prx = env().get_proxy())?
      log.debug "| using proxy #{prx}"
      opts.proxy = prx

    if not tls then # noop
    else if opts.proxy? and (pcc = proxyca.get())?
      log.debug "| Using proxy CA certs #{pcc.files().join(':')}"
      opts.ca = pcc.data().concat [ ca ]
    else if (ca = certs[uri_fields.hostname])?
      log.debug "| Adding a custom CA for host #{uri_fields.hostname} when tls=#{tls}"
      opts.ca = [ ca ]

    tor.agent(opts)

    await request opts, defer err, res, body
    if err? then err = @error_for_humans {err, uri : opts.uri, uri_fields }
    else if not (res.statusCode in http_status)
      if res.statusCode is 400 and res.headers?["x-keybase-client-unsupported"]
        v = res.headers["x-keybase-client-upgrade-to"]
        err = new E.RequiredUpgradeError "Upgrade is required! Run `keybase-installer` to upgrade to v#{v}"
        err.upgrade_to = v
      else
        err = new E.HttpError "Got reply #{res.statusCode}"
    else if json and not(body?.status?.name in kb_status)
      err = new E.KeybaseError "#{body.status.desc} (error ##{body.status.code})"
      err.fields = body.status?.fields or {}
      opts.agent = null
      log.debug "Full request: #{JSON.stringify opts}"
      log.debug "Full reply: #{JSON.stringify body}"
    else
      if (v = res.headers["x-keybase-client-upgrade-to"])? and not @_warned
        log.warn "Upgrade suggested! Run `keybase-installer` to upgrade to v#{v}"
        @_warned = true
      @_find_cookies res

    # Note the swap --- we care more about the body in most cases.
    log.debug "- request to #{endpoint} -> #{err}"
    cb err, body, res

  #-----------------

  post : (args, cb) -> @req m(args, "POST"), cb
  get  : (args, cb) -> @req m(args, "GET") , cb
  cookies : () -> @_cookies

#=================================================

exports.client = _cli = new Client()

for k of Client.prototype
  ((fname) -> exports[fname] = (args...) -> _cli[fname] args...)(k)

#=================================================

