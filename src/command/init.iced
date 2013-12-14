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

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : []
      help : "make an initial configuration file"
    name = "init"
    sub = scp.addParser name, opts
    opts.aliases.concat [ name ]

  #----------

  run : (cb) ->
    err = null
    c = env().config
    if c.is_empty()
      c.set "comments", [ "an empty config file" ]
      await c.write defer err
    else
      log.warn "keybase has already been initialized; see '#{c.filename}'"
    cb err

##=======================================================================

