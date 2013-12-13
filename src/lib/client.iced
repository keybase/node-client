rpc = require 'framed-msgpack-rpc'
{constants} = require './constants'
log = require './log'
{E} = require './err'

#=========================================================================

rpc.pack.use_byte_arrays()

#=========================================================================

exports.Client = class Client

  constructor : ({@path}) ->
    @_x = new rpc.RobustTransport { @path }

  init : (cb) ->
    await @_x.connect defer err
    if err?
      log.error "Error connecting to socket: #{err}"
      @_x = null
    else
      @_cli = new rpc.Client @_x, constants.PROT
    cb err

  _call_check : (meth, arg, cb, codes = [ E.OK ]) ->
    ok = false
    await @_cli.invoke meth, arg, defer err, res
    if err?
      log.error "Error in #{meth}: #{err}"
    else if res?.rc is E.OK
      err = null
    else if res?.rc in codes
      err = new E.error[res.rc]
    else
      log.error "Got bad code from #{meth}: #{res.rc}"
      err = new E.error[res.rc]
      res = null
    cb err, res

  ping : (cb) ->
    await @_call_check "ping", {}, defer err
    cb err

  send_download : (obj, cb) ->
    await @_call_check "download", obj, defer(err), [ E.OK, E.DUPLICATE ]
    cb err

  @make : (path, cb) ->
    x = new Client { path }
    await x.init defer err
    x = null if err?
    cb err, x

#==============================================ok===========================

_g = {}

exports.client = () -> _g.client

exports.init_client = (path, cb) ->
  await Client.make path, defer err, _g.client
  cb err

#=========================================================================
