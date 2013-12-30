request = require 'request'
{env} = require './env'
urlmod = require 'url'
{E} = require './err'
log = require './log'

#=================================================

m = (dict, method) ->
  dict.method = method
  dict

#=================================================

exports.Client = class Client 

  constructor : (@headers) ->
    @_cookies = {}
    @_session = null
    @_csrf = null

  #--------------

  set_headers : (h) -> @headers = h
  get_headers : ()  -> @headers
  add_headers : (d) ->
    @headers or= {}
    (@headers[k] = v for k,v of d)
    true

  #-----------------

  set_session : (s) ->
    @add_headers { "X-Keybase-Session" : s }
    @_session = s

  #-----------------

  set_csrf : (c) ->
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

  req : ({method, endpoint, args, http_status, kb_status}, cb) ->
    opts = { method, json : true, jar : true }
    opts.headers = @headers if @headers?

    kb_status or= [ "OK" ]
    http_status or= [ 200 ]

    uri_fields = {
      protocol : "http#{if env().get_no_tls() then '' else 's'}"
      hostname : env().get_host()
      port : env().get_port()
      pathname : [ env().get_api_uri_prefix(), (endpoint + ".json") ].join("/")
    }
    uri_fields.query = args if method in [ 'GET', 'DELETE' ]
    opts.uri = urlmod.format uri_fields
    if method is 'POST'
      opts.body = args

    await request opts, defer err, res, body
    if err? then #noop
    else if not (res.statusCode in http_status) 
      err = new E.HttpError "Got reply #{res.statusCode}"
    else if not (body?.status?.name in kb_status)
      err = new E.KeybaseError "#{body.status.desc} (error ##{body.status.code})"
      err.fields = body.status?.fields or {}
      log.debug "Full request: #{JSON.stringify opts}"
      log.debug "Full reply: #{JSON.stringify body}"
    else
      @_find_cookies res

    # Note the swap --- we care more about the body in most cases.
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

