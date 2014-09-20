
SocksHttpAgent = require('socks5-http-client/lib/Agent')
{env} = require './env'
log = require './log'

#-----------------

hidden_address = (null_ok) -> env().get_tor_hidden_address(null_ok)
proxy = (null_ok) -> env().get_tor_proxy(null_ok)
enabled = () -> env().get_tor()? or proxy(true)? or hidden_address(true)?

#-----------------

agent = () -> 
  if enabled()
    px = proxy(false)
    log.debug "| Setting tor proxy to #{JSON.stringify px}"
    new SocksHttpAgent { socksPort : px.port, socksHost : px.hostname }
  else
    null

#-----------------

module.exports = { hidden_address, proxy, enabled, agent }
