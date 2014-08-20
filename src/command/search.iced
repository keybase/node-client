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

SERVICES = [ "github", "twitter", "reddit", "hackernews"  ]

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

  reformat_results : (list) ->
    ret = []
    for entry in list when (c = entry.components)?
      obj = 
        username : c.username.val
        key : c.key_fingerprint?.val.replace(/\s+/g, "")
      for svc in SERVICES
        if (n = c[svc])? then obj[svc] = n.val
      if c.websites?.length
        obj.websites = ("#{v.protocol}//#{v.val}" for v in c.websites)
      obj.score = entry.total_score
      if @logged_in
        obj.is_followee = entry.is_followee
      ret.push obj
    return ret

  #-----------

  display : (v) ->
    if @argv.json then @display_json v
    else @display_text v

  #-----------

  display_text : (v) ->
    lines = []
    for rec in v
      fields = []
      if @logged_in
        fields.push(if rec.is_followee then '*' else '-')
      fields.push(rec.username, rec.key)
      for svc in SERVICES
        if (n = rec[svc])
          fields.push "#{svc}:#{n}"
      if (tmp = rec.websites)?
        fields = fields.concat tmp
      line = fields.join("\t")
      lines.push line
    return lines.join("\n")

  #-----------

  display_json : (v) ->
    JSON.stringify(v, null, "  ")

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @search esc defer list
    if (v = list?.completions) and v.length
      await session.load_and_check esc defer @logged_in
      v = @reformat_results v
    else
      v = []
    log.console.log d if (d = @display v).length
    cb null, (if v.length is 0 then 1 else 0)

  #-----------------

##=======================================================================

