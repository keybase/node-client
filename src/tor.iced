
SocksHttpAgent = require('socks5-http-client/lib/Agent')
SocksHttpsAgent = require('socks5-https-client/lib/Agent')
{env} = require './env'
log = require './log'

#-----------------

hidden_address = (null_ok) -> env().get_tor_hidden_address(null_ok)
proxy = (null_ok) -> env().get_tor_proxy(null_ok)
enabled = () -> env().get_tor()? or proxy(true)? or hidden_address(true)? or strict() or leaky()
leaky = () -> env().get_tor_leaky()
strict = () -> env().get_tor_strict() and not leaky()

#-----------------

agent = (opts) ->
  if enabled()
    px = proxy(false)
    uri = opts.uri or opts.url
    chk = (s) -> s.indexOf('https') is 0
    tls = if typeof(uri) is 'string' and chk(uri) then true
    else if typeof(uri) is 'object' and chk(uri.protocol) then true
    else false
    log.debug "| Setting tor proxy to #{JSON.stringify px}; tls=#{tls}"
    klass = if tls then SocksHttpsAgent else SocksHttpAgent
    opts.agent = new klass { socksPort : px.port, socksHost : px.hostname }

#-----------------

module.exports = { hidden_address, proxy, enabled, agent, strict, leaky }
