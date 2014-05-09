codesign              = require 'codesign'
path                  = require 'path'
fs                    = require 'fs'
{Base}                = require './base'
log                   = require '../log'
{add_option_dict}     = require './argparse'
{E}                   = require '../err'
{TrackSubSubCommand}  = require '../tracksubsub'
{gpg}                 = require '../gpg'
{make_esc}            = require 'iced-error'
{User}                = require '../user'
{keypull}             = require '../keypull'
{BufferInStream}      = require 'iced-spawn'

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

  do_sign : (payload, cb) ->
    esc = make_esc cb, "Command::do_sign"
    gargs =
      args:  [ "--sign", "--detach-sign", "-a", "-u", (@me.fingerprint true) ]
      stdin: new BufferInStream(new Buffer(payload, 'utf8'))
    await gpg gargs, esc defer out
    cb null, out.toString 'utf8'

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
    ignore     = if rel_ignore[...2] isnt '..' then ["/#{rel_ignore}"] else []
    return ignore

  #----------

  target_file_to_json: (fname, cb) ->
    ###
    returns     null, null  # if there is no target file,
    otherwise:  err, obj
    ###
    log.debug "+ Command::target_file_to_json"
    obj = null
    err = null
    await fs.readFile fname, 'utf8', defer f_err, body
    if body?
      obj = codesign.markdown_to_obj body
      if not obj?
        err = new E.CorruptionError "Could not parse file #{fname}"
    log.debug "- Command::target_file_to_json"
    cb err, obj

  #----------

  sign: (cb) ->
    log.debug "+ Command::sign"
    esc = make_esc cb, "Command::sign"

    #
    # make sure we're logged in, have key
    #
    await keypull { stdin_blocked : @is_batch(), need_secret : true }, esc defer()
    await @load_me esc defer()

    my_username = "https://keybase.io/#{@me.username()}"

    #
    # let's walk the code
    #
    await @get_preset_list esc defer preset_list
    cs = new codesign.CodeSign @argv.dir, {ignore: @get_ignore_list(), presets: preset_list}
    await cs.walk esc defer()

    #
    # see if there's already a signed file and if it still
    # matches, we can pull any existing signers into our new one
    #
    await @target_file_to_json @argv.output, esc defer old_obj
    if old_obj?
      log.info "Found existing #{@argv.output}"
      await cs.compare_to_json_obj old_obj, defer probs
      if not probs.length
        for {signer, signature} in old_obj.signatures when signer isnt my_username
          cs.attach_sig signer, signature
          log.info "Re-attaching still-valid signature from #{signer}"

    #
    # attach our own signature
    #
    await @do_sign cs.signable_payload(), esc defer sig
    cs.attach_sig my_username, sig

    #
    # output
    #
    md = codesign.obj_to_markdown cs.to_json_obj()
    await fs.writeFile @argv.output, md, {encoding: 'utf8'}, esc defer()

    log.debug "- Command::sign"
    cb()

  #----------

  run : (cb) ->
    #console.log @argv
    esc = make_esc cb, "Command::run"
    log.debug "+ Command::run"
    switch @argv.codesign_subcommand
      when 'sign'   then await @sign   esc defer()
      when 'verify' then await @verify esc defer()
      when 'tojson' then await @tojson esc defer()
    log.debug "- Command::run"
    cb null

##=======================================================================

