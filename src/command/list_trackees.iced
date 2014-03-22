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

  use_session : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      help : "list people you are tracking"
      aliases : [ "trackees" ]
    name = "list-trackees"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return [ name ].concat opts.aliases

  #----------

  sort_list : (v) ->
    sort_fn = (a,b) ->
      a = ("" + a).toLowerCase()
      b = ("" + b).toLowerCase()
      if a < b then -1 
      else if a > b then 1
      else 0
    if not v? then []
    else
      v = ( [ pj.body.track.basics.username, pj ] for pj in v)
      v.sort sort_fn
      out = {}
      for [k,val] in v
        out[k] = val
      out

  #----------

  condense_record : (o) ->
    rps = [] unless (rps = o.body.track.remote_proofs)?
    proofs = (v for rp in rps when (v = rp?.remote_key_proof?.check_data_json))
    out = 
      uid : o.body.track.id
      key : o.body.track.key.key_fingerprint
      proofs : proofs
      ctime : o.ctime
    return out

  #----------

  condense_records : (d) ->
    out = {}
    for k,v of d
      out[k] = @condense_record v
    out

  #----------

  display_json : (d) ->
    unless @argv.verbose
      d = @condense_records d
    JSON.stringify d, null, "  "

  #----------

  display : (v) ->
    if @argv.json then @display_json v
    else null

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"

    if (un = env().get_username())?
      await session.check esc defer logged_in
      await User.load_me {secret : false}, esc defer me
      list = @sort_list me.list_trackees()
      log.console.log @display list
    else
      log.warn "Not logged in"
    cb null

  #-----------------

##=======================================================================

