{Base} = require './base'
log = require '../log'
{add_option_dict} = require './argparse'
{session} = require '../session'
{make_esc} = require 'iced-error'
{env} = require '../env'
log = require '../log'
{User} = require '../user'
{format_fingerprint} = require('pgp-utils').util
util = require 'util'
{E} = require '../err'
{constants} = require '../constants'
ST = constants.signature_types
{tablify} = require 'tablify'
timeago = require 'timeago'
{LinkTable} = require '../chainlink'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS :
    r :
      alias : 'revoked'
      action : 'storeTrue'
      help : 'show revoked signatures too'
    v :
      alias : 'verbose'
      action : 'storeTrue'
      help : 'a full dump, with more gory details'
    j :
      alias : 'json'
      action : 'storeTrue'
      help : 'output in json format; default is simple text list'
    t :
      alias : 'type'
      action : "append"
      help : 'the type of signatures to output; choose from ["track","proof","currency","self"]; all by default'

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  TYPES :
    track : ST.TRACK
    proof : ST.REMOTE_PROOF
    currency : ST.CRYPTOCURRENCY
    self : ST.SELF_SIG

  #----------

  add_subcommand_parser : (scp) ->
    opts =
      help : "list of your non-revoked signatures"
      aliases : [ "list-sigs" ]
    name = "list-signatures"
    sub = scp.addParser name, opts
    sub.addArgument [ "filter" ], { nargs : '?', help : "a regex to filter by" }
    add_option_dict sub, @OPTS
    return [ name ].concat opts.aliases

  #----------

  display_json : (list) ->
    JSON.stringify list, null, "  "

  #----------

  display : (list) ->
    if @argv.json then @display_json list
    else @display_text list

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

  display_text : (list) ->
    rows = for {seqno,id,type,ctime,live,payload} in list
      row = [ seqno,
        (if @argv.verbose then id else id[0..8] + "..." ),
        type,
        timeago(new Date(ctime*1000)),
      ]
      if (@argv.revoked) then row.push (if live then "+" else "-")
      row.push (if typeof(payload) is 'string' then payload else JSON.stringify(payload))
      row

    tablify rows, {
      row_start : ' '
      row_end : ''
      spacer : '  '
      row_sep_char : ''
    }

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

  parse_types : (cb) ->
    types = null
    err = null
    if @argv.type?
      for t in @argv.type
        unless (k = @TYPES[t])?
          err = new E.ArgsError "Bad signature type specified: #{t}"
          break
        types or= []
        types.push k
      @types = types unless err?
    cb err

  #----------

  parse_args : (cb) ->
    esc = make_esc cb, "Command::parse_args"
    await @parse_filter esc defer()
    await @parse_types esc defer()
    cb null

  #----------

  parse_filter : (cb) ->
    err = null
    @filter_rxx = null
    if (f = @argv.filter)? and f.length
      try
        @filter_rxx = new RegExp(f, "i")
      catch e
        err = new E.ArgsError "Bad regex specified: #{e.message}"
    cb err

  #----------

  select_sigs : (me) ->
    if not (tab = me.sig_chain.table)? then tab = new LinkTable()
    else if @types? then tab = tab.select(@types)
    tab

  #----------

  filter_sigs : (tab) ->
    if @filter_rxx?
      tab.prune (obj) => not(obj.matches(@filter_rxx))

  #----------

  list_sigs : (tab) ->
    list = (p.summary() for p in tab.flatten())

  #----------

  sort_sigs : (list) ->
    list.sort (a,b) -> (a.seqno - b.seqno)

  #----------

  process_sigs : (me) ->
    tab = @select_sigs me
    @filter_sigs tab
    list = @list_sigs tab
    @sort_sigs list
    list

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_args esc defer()
    if (un = env().get_username())?
      await session.check esc defer logged_in
      verify_opts = { show_revoked : @argv.revoked, show_perm_failures : true }
      await User.load_me {secret : false, verify_opts }, esc defer me
      list = @process_sigs me
      list = @display list
      log.console.log list if list.length
    else
      log.warn "Not logged in"
    cb null

  #-----------------

##=======================================================================

