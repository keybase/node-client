{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{gpg} = require '../gpg'
{BufferOutStream} = require '../stream'
{E} = require '../err'
{env} = require '../env'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    get :
      help : "Read the given configuration option"

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : ["conf"]
      help : "make an initial configuration file"
    name = "config"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    sub.addArgument ["kvs"], { nargs : "*" }
    opts.aliases.concat [ name ]

  #----------

  config_opts : () -> { in_config : true }

  #----------

  run : (cb) ->
    err = null
    c = env().config
    if (k = @argv.get)?
      console.log c.get k
    else if @argv.kvs.length > 2
      msg = "Need either 0,1 or 2 arguments for setting values in config"
      log.error "Usage: #{msg}"
      err = new E.ArgsError msg
    else if @argv.kvs.length > 0
      k = @argv.kvs[0]
      v = if @argv.kvs.length is 2 then @argv.kvs[1] else null
      c.set k, v
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

