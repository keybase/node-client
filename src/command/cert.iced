{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{version_info} = require '../version'
{certs} = require '../ca'
{env} = require '../env'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    a :
      alias : 'all'
      action : 'storeTrue'
      help : "list all possible certs in JSON form"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "print out the CA cert the client uses to authorize HTTPS connections"
    name = "cert"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument [ "host" ], { nargs : '?', help : "which host to authorize"  }
    return [ name ]

  #----------

  run : (cb) ->
    if @argv.all
      log.console.log JSON.stringify(certs, null, "   ")
    else 
      unless (h = @argv.host)?
        h = env().get_host()
        log.info "Cert for #{h} ->"
      log.console.log certs[h]
    cb null

##=======================================================================

