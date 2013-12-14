
request = require 'request'
env = require './env'

#=================================================

class Client 

  constructor : () ->
    @headers = null

  set_headers : (h) -> @headers = arg
  get_headers : ()  -> @headers
  add_headers : (d) ->
    @headers or= {}
    (@headers[k] = v for k,v of d)
    true

  req : (opts, cb) ->
    opts.headers = @headers if @headers?
    opts.json = true
    await request opts, defer err, response, body
    cb err, response, body

#=================================================