{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
{PackageJson} = require '../package'
{session} = require '../session'
{make_esc} = require 'iced-error'
{env} = require '../env'
log = require '../log'
{User} = require '../user'
{format_fingerprint} = require('pgp-utils').util
util = require 'util'
{E} = require '../err'
req = require '../req'

##=======================================================================


##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    v :
      alias : 'verbose'
      action : 'storeTrue'
      help : 'a full dump, with more gory details'
    j :
      alias : 'json'
      action : 'storeTrue'
      help : 'output in json format; default is simple text list'

  #----------

  use_session : () -> false
  needs_configuration : () -> false

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "search all users"
      aliases : [ ]
    name = "search"
    sub = scp.addParser name, opts
    sub.addArgument [ "query" ], { nargs : 1, help : "a substring to find" }
    add_option_dict sub, @OPTS
    return [ name ].concat opts.aliases

  #----------

  search : (cb) ->
    args =
      endpoint : "user/autocomplete"
      args :
        q : @argv.query[0]
    await req.get args, defer err, body
    cb err, body

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @search esc defer list
    console.log JSON.stringify(list, null, "  ")
    cb null

  #-----------------

##=======================================================================

