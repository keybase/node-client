codesign              = require 'codesign'
path                  = require 'path'
{Base}                = require './base'
log                   = require '../log'
{add_option_dict}     = require './argparse'
{E}                   = require '../err'
{TrackSubSubCommand}  = require '../tracksubsub'
{gpg}                 = require '../gpg'
{make_esc}            = require 'iced-error'
{User}                = require '../user'
{keypull}             = require '../keypull'

##=======================================================================

exports.Command = class Command extends Base

  #----------

  SIGN_OPTS:
    o:
      alias:        'output'
      type:         'string'
      help:         'the output file'
      defaultValue: codesign.constants.defaults.FILENAME
    p:
      alias:        'presets'
      action:       'store'
      type:         'string'
      help:         'specify ignore presets, comma-separated'
      defaultValue: 'git,dropbox,kb'
    d:
      alias:        'dir'
      action:       'store'
      type:         'string'
      help:         'the directory to sign'
      defaultValue: '.'
    q:
      alias:        'quiet'
      action:       'storeTrue'
      help:         'withhold output unless an error'

  #----------

  VERIFY_OPTS: 
    i:
      alias:        'input'
      type:         'string'
      help:         'the input file'
      defaultValue: codesign.constants.defaults.FILENAME
    d:
      alias:        'dir'
      action:       'store'
      type:         'string'
      help:         'the directory to sign'
      defaultValue: '.'
    q:
      alias:        'quiet'
      action:       'storeTrue'
      help:         'withhold output unless an error'
    s: 
      alias:        'strict'
      action:       'storeTrue'
      help:         'fail on warnings (typically cross-platform problems)'

  #----------

  TOJSON_OPTS:
    i:
      alias:        'input'
      type:         'string'
      help:         'the input file to convert to JSON'
      defaultValue: codesign.constants.defaults.FILENAME

  #----------

  is_batch : -> false

  #----------

  set_argv : (a) ->
    # can return a new E.ArgsError if there's a prob
    super a

  #----------

  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "code-sign" ]
      help : "sign or verify a directory's contents"
    name = "codesign"
    sub = scp.addParser name, opts

    sub2 = sub.addSubparsers {
      title: "codesign subcommand"
      dest:  "codesign_subcommand"
    }
    # add the three subcommands
    ss1 = sub2.addParser "sign", {help: "sign a directory's contents"}
    add_option_dict ss1, @SIGN_OPTS

    ss2 = sub2.addParser "verify", {help: "verify a directory's contents"}
    add_option_dict ss2, @VERIFY_OPTS

    ss3 = sub2.addParser "tojson", {help: "convert a signed manifest to JSON"}
    add_option_dict ss3, @TOJSON_OPTS

    return opts.aliases.concat [ name ]

  #----------

  do_sign : (cb) ->
    args = [ "--sign", "-u", (@me.fingerprint true) ]
    gargs = { args }
    args.push "-a"  unless @argv.binary
    args.push "--clearsign" if @argv.clearsign
    args.push "--detach-sign" if @argv.detach_sign
    args.push("--output", o ) if (o = @argv.output)?
    if @argv.message
      gargs.stdin = new BufferInStream @argv.message 
    else if @argv.file?
      args.push @argv.file 
    else
      gargs.stdin = process.stdin
    await gpg gargs, defer err, out
    unless @argv.output
      log.console.log out.toString( if @argv.binary then 'utf8' else 'binary' )
    cb err 

  #----------

  load_me : (cb) ->
    await User.load_me {secret : true}, defer err, @me
    cb err

  #----------

  get_preset_list: (cb) ->
    err           = null
    presets       = @argv.presets.split ','
    valid_presets = (k for k of codesign.constants.presets)
    for k in presets
      if not codesign.CodeSign.is_valid_preset k
        err     = new E.ArgsError "Unknown preset #{k} (valid values = #{valid_presets.join ','})"
        presets = null
        break
    cb err, presets

  # ----------

  get_ignore_list: ->
    # if the output file is inside the analyzed directory, add
    # it to the ignore array. Otherwise don't worry about it.
    rel_ignore = path.relative(@argv.dir, @argv.output).split(path.sep).join('/')
    ignore = if rel_ignore[...2] isnt '..' then ["/#{rel_ignore}"] else []
    return ignore

  #----------

  sign: (cb) ->
    # await keypull { stdin_blocked : @is_batch(), need_secret : true }, esc defer()
    # await @load_me esc defer()
    # await @do_sign esc defer()
    log.debug "+ Command::sign"
    esc = make_esc cb, "Command::sign"
    await @get_preset_list esc defer preset_list
    cs = new codesign.CodeSign @argv.dir, {ignore: @get_ignore_list(), presets: preset_list}
    log.debug "walking"
    await cs.walk esc defer()
    log.debug "walked"
    log.debug "- Command::sign"
    cb()

  #----------

  run : (cb) ->
    console.log @argv
    esc = make_esc cb, "Command::run"
    log.debug "+ Command::run"
    switch @argv.codesign_subcommand
      when 'sign'   then await @sign   esc defer()
      when 'verify' then await @verify esc defer()
      when 'tojson' then await @tojson esc defer()
    log.debug "- Command::run"
    cb null

##=======================================================================

