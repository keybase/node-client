{Base} = require './base'
log = require '../log'
{ArgumentParser} = require 'argparse'
{add_option_dict} = require './argparse'
C = require('../constants').constants
ST = C.signature_types
ACCTYPES = C.allowed_cryptocurrency_types
{PackageJson} = require '../package'
{E} = require '../err'
{make_esc} = require 'iced-error'
{prompt_yn,prompt_remote_name} = require '../prompter'
{User} = require '../user'
{req} = require '../req'
assert = require 'assert'
session = require '../session'
S = require '../services'
{dict_union} = require '../util'
iutils = require 'iced-utils'
{drain} = iutils.drain
{a_json_parse} = iutils.util
util = require 'util'
fs = require 'fs'
proofs = require 'keybase-proofs'
bitcoyne = require 'bitcoyne'
{AnnouncementSigGen} = require '../sigs'

##=======================================================================

stream_open = (f, cb) ->
  ret = fs.createReadStream f
  ret.on 'error', (err) -> 
    err = new E.NotFoundError "Could not open file '#{f}': #{err.code}"
    cb err, null
  ret.on 'open', () -> cb null, ret

##=======================================================================

exports.Command = class Command extends Base

  #----------

  OPTS : 
    j :
      alias : 'json'
      action : 'storeTrue'
      help : 'interpret the announcement as JSON object'
    e :
      alias : 'encode'
      action : 'storeTrue'
      help : 'encode the announcement with base64-encoding'
    f : 
      alias : 'file'
      help : 'Specify a file as the announcment'
    m:
      alias : 'message'
      help : 'Specify a message as the announcement"'

  #----------

  use_session : () -> true
  needs_configuration : () -> true

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ ]
      help : "make an announcement, stored to your signature chain"
    name = "announce"
    sub = scp.addParser name, opts
    add_option_dict sub, @OPTS
    return opts.aliases.concat [ name ]

  #----------

  parse_args : (cb) ->
    err = null
    if @argv.encode and @argv.json
      err = new E.ArgsError "can't specify both -j/--json and -e/--encode"
    else if @argv.file and @argv.message
      err = new E.ArgsError "can't specify both -f/--file and -m/--message"
    cb err

  #----------

  allocate_proof_gen : (cb) ->
    klass = AnnouncementSigGen
    arg = { @announcement }
    await @me.gen_sig_base { klass, arg }, defer err, @gen
    cb err

  #----------

  load_announcement : (cb) ->
    stream = null
    esc = make_esc cb, "Command::load_announcement"
    if (m = @argv.message)? then @raw = new Buffer m, 'utf8'
    else if (f = @argv.file)?
      await stream_open f, esc defer stream
    else
      stream = process.stdin
    if stream?
      await drain stream, esc defer @raw
    cb null

  #----------

  encode_ennouncement : (cb) ->
    esc = make_esc cb, "Command::encode_announcement"
    if @argv.json
      await a_json_parse @raw.toString('utf8'), esc defer data
      encoding = "json"
    else if @argv.encode
      data = @raw.toString('base64')
      encoding = "base64"
    else
      encoding = "utf8"
      data = @raw.toString('utf8')
    @announcement = { data, encoding }
    cb null

  #----------

  run : (cb) ->
    esc = make_esc cb, "Command::run"
    await @parse_args esc defer()
    await session.login esc defer()
    await User.load_me { secret : true }, esc defer @me
    await @load_announcement esc defer()
    await @encode_ennouncement esc defer()
    await @allocate_proof_gen esc defer()
    await @gen.run esc defer()
    log.info "Success!"
    cb null

##=======================================================================

