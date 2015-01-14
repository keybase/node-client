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
  needs_configuration : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts =
      help : "list people you are tracking"
      aliases : [ ]
    name = "list-tracking"
    sub = scp.addParser name, opts
    sub.addArgument [ "filter" ], { nargs : '?', help : "a regex to filter by" }
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
    if not v? then {}
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
      key : o.body.track.key.key_fingerprint?.toUpperCase()
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
    else @display_text v

  #----------

  display_text_line : (k,v) ->
    fields = [ k ]
    if @argv.verbose
      fields.push(v.key, v.ctime)
      proofs = []
      for p in v.proofs
        if p.name? and p.username?
          proofs.push "#{p.name}:#{p.username}"
      proofs.sort()
      fields = fields.concat proofs
    fields.join("\t")

  #----------

  display_text : (d) ->
    d = @condense_records d
    lines = (@display_text_line(k,v) for k,v of d)
    lines.join("\n")

  #----------

  filter_list : (d) ->
    if @filter_rxx?
      out = {}
      for k,v of d
        if k.match(@filter_rxx)
          out[k] = v
        else if (rps = v.body?.track?.remote_proofs)?
          for proof in rps when (cd = proof?.remote_key_proof?.check_data_json)?
            if cd.username?.match(@filter_rxx) or cd.hostname?.match(@filter_rxx)
              out[k] = v
              break
      d = out
    d

  #----------

  parse_filter : (cb) ->
    err = null
    if (f = @argv.filter)? and f.length
      try
        @filter_rxx = new RegExp(f, "i")
      catch e
        err = new E.ArgsError "Bad regex specified: #{e.message}"
    cb err

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_filter esc defer()

    if (un = env().get_username())?
      await session.check esc defer logged_in
      await User.load_me {secret : false}, esc defer me
      list = @sort_list me.list_trackees()
      list = @filter_list list
      log.console.log @display list
    else
      log.warn "Not logged in"
    cb null

  #-----------------

##=======================================================================

