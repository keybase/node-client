{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require 'gpg-wrapper'
{E} = require '../err'
{env} = require '../env'
{a_json_parse} = require('iced-utils').util
urlmod = require 'url'

##=======================================================================

convert = (s) ->
  if not s? then null
  else if s is 'true' then true
  else if s is 'false' then false
  else if s.match(/^[0-9]+$/) and not(isNaN(i = parseInt(s,10))) then i
  else s

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    get :
      help : "Read the given configuration option"
    j :
      alias : 'json'
      help : 'interpret the value as JSON'
      action : 'storeTrue'
    pretty :
      help : "pretty-print JSON"
      action : 'storeTrue'
    s :
      alias : "server"
      help : "specify which server to use"
    S :
      alias : "reset-server"
      help  : "reset the server to default"
      action : 'storeTrue'

  #----------

  add_subcommand_parser : (scp) ->
    opts =
      aliases : [ ]
      help : "make an initial configuration file"
    name = "config"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument ["kvs"], { nargs : "*" }
    opts.aliases.concat [ name ]

  #----------

  config_opts : () -> { quiet : true }
  use_gpg : () -> false

  #----------

  run : (cb) ->
    err = null
    c = env().config
    if (k = @argv.get)?
      console.log JSON.stringify(c.get(k), null, (if @argv.pretty then "    " else null))
    else if (s = @argv.server)?
      if (url = urlmod.parse(s))?
        c.set("server.no_tls", true) if url.protocol is "http:"
        c.set("server.port", parseInt(p, 10)) if (p = url.port)?
        c.set("server.host", h) if (h = url.hostname)?
      else
        msg = "Couldn't parse server URL #{url}"
        log.error msg
        err = new E.ArgsError msg
    else if @argv.reset_server
      c.set("server", null)
    else if @argv.kvs.length > 2
      msg = "Need either 0,1 or 2 arguments for setting values in config"
      log.error "Usage: #{msg}"
      err = new E.ArgsError msg
    else if @argv.kvs.length > 0
      k = @argv.kvs[0]
      if @argv.json and (@argv.kvs.length is 2)
        await a_json_parse @argv.kvs[1], defer err, v
      else
        v = convert(if @argv.kvs.length is 2 then @argv.kvs[1] else null)
      c.set k, v unless err?
    else if c.is_empty()
      pjs = new PackageJson()
      c.set "generated", {
          by : "keybase v#{pjs.version()}"
          on : (new Date()).toString()
      }
    else
      log.warn "keybase has already been initialized; see '#{c.filename}'"
    if not err and c.is_dirty()
      await c.write defer err
    cb err

##=======================================================================

