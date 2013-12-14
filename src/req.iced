request = require 'request'
env = require './env'
urlmod = require 'url'

#=================================================

class Client 

  constructor : (@headers) ->

  #--------------

  set_headers : (h) -> @headers = h
  get_headers : ()  -> @headers
  add_headers : (d) ->
    @headers or= {}
    (@headers[k] = v for k,v of d)
    true

  #-----------------

  req : ({method, endpoint, args}, cb) ->
    opts = { method, json : true }
    opts.headers = @headers if @headers?

    uri_fields = {
      protocol : "http#{if env().get_no_tls() then '' else 's'}"
      hostname : env().get_host()
      port : env().get_port()
      pathname : [ env().get_api_uri_prefix(), endpoint].join("/")
    }
    uri_fields.query = args if method in [ 'GET', 'DELETE' ]
    opts.uri = urlmod.format uri_fields
    if method is 'POST'
      opts.body = args

    await request opts, defer err, response, body
    cb err, response, body

  #-----------------

  post : (endpoint, args, cb) -> @req { method : 'POST', endpoint, args }, cb
  get : (endpoint, args, cb) -> @req { method : 'GET', endpoint, args }, cb

#=================================================

_cli = new Client()

module.exports =
  client : _cli
  Client : Client
  get    : (args...) -> _cli.get args...
  post   : (args...) -> _cli.post args...
  req    : (args...) -> _cli.req args...

#=================================================

