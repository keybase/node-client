codesign                  = require 'codesign'
path                      = require 'path'
fs                        = require 'fs'
{Base}                    = require './base'
log                       = require '../log'
{add_option_dict}         = require './argparse'
{E}                       = require '../err'
{TrackSubSubCommand}      = require '../tracksubsub'
{gpg}                     = require '../gpg'
{make_esc,chain}          = require 'iced-error'
{athrow}                  = require('iced-utils').util
{User}                    = require '../user'
{keypull}                 = require '../keypull'
{BufferInStream}          = require 'iced-spawn'
{master_ring}             = require '../keyring'
{write_tmp_file}          = require('iced-utils').fs
{DecryptAndVerifyEngine}  = require '../dve'

##=======================================================================

class MyEngine extends DecryptAndVerifyEngine

  constructor : ({argv}) ->
    @_tmp_files = {}
    super {argv}

  #---------------

  write_tmp : ( {file, data}, cb) ->
    await write_tmp_file { data, base : file, mode : 0o600 }, defer err, nm
    unless err?
      @_tmp_files[file] = nm
      log.debug "| writing #{file} tmpfile #{nm}"
    cb err

  #---------------

  cleanup_run1 : (cb) ->
    if @argv.preserve_tmp_files
      log.debug "| preserving temporary files by command-line flag"
    else
      for k,v of @_tmp_files
        log.debug "| unlink #{v}"
        await fs.unlink v, defer err
        if err?
          log.warn "Could not remove tmp file #{v}: #{err.message}"
    cb()

  #---------------

  patch_gpg_args : (args) ->
    args.push "--verify"

  #---------------

  get_files : (args) ->
    args.push @_tmp_files.sig
    args.push @_tmp_files.payload

  #---------------

  run1 : ({username, payload, signature}, cb) ->
    cb = chain cb, @cleanup_run1.bind(@)
    esc = make_esc cb, "MyEngine::run_one"
    await @write_tmp { file : "payload", data : payload }, esc defer()
    await @write_tmp { file : "sig", data : signature }, esc defer()
    await @run esc defer()
    err = null
    if @username isnt username
      err = E.UsernameMismatchError "bad username: wanted #{username} but got #{@username}"
    cb err

##=======================================================================

exports.Command = class Command extends Base

  DIR_OPT:
    nargs:          '?'
    action:         'store'
    type:           'string'
    help:           'the directory to sign/verify'
    defaultValue:   '.'

  #----------

  SIGN_OPTS:
    o:
      alias:        'output'
      type:         'string'
      help:         'the output file'
    p:
      alias:        'presets'
      action:       'store'
      type:         'string'
      help:         'specify ignore presets, comma-separated'
      defaultValue: 'git,dropbox,kb'
    q:
      alias:        'quiet'
      action:       'storeTrue'
      help:         'withhold output unless an error'

    # dir: this is added below, since the nargs format doesn't work
    #   with the add_option_dict function

  #----------

  VERIFY_OPTS: 
    i:
      alias:        'input'
      type:         'string'
      help:         'the input file'
    q:
      alias:        'quiet'
      action:       'storeTrue'
      help:         'withhold output unless an error'
    s: 
      alias:        'strict'
      action:       'storeTrue'
      help:         'fail on warnings (typically cross-platform problems)'
    P : 
      alias:        'preserve-tmp-files'
      action:       'storeTrue'
      help:         'preserve temp files for debugging and inspection'
    "ignore-verify-errors":
      action :      'storeTrue'
      help   :      'ignore verify errors and continue to tracking'
    # dir: this is added below, since the nargs format doesn't work
    #   with the add_option_dict function

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
  copy: (d) ->
    x    = {}
    x[k] = v for k,v of d
    x
  #----------


  add_subcommand_parser : (scp) ->
    opts = 
      aliases : [ "code-sign" ]
      help : "sign or verify a directory's contents"
    name = "dir"
    sub = scp.addParser name, opts

    sub2 = sub.addSubparsers {
      title: "dir subcommand"
      dest:  "dir_subcommand"
    }
    # add the three subcommands
    ss1 = sub2.addParser "sign", {help: "sign a directory's contents"}
    add_option_dict ss1, @SIGN_OPTS
    ss1.addArgument ['dir'], @copy(@DIR_OPT)

    ss2 = sub2.addParser "verify", {help: "verify a directory's contents"}
    add_option_dict ss2, @VERIFY_OPTS
    add_option_dict ss2, DecryptAndVerifyEngine.OPTS
    ss2.addArgument ['dir'], @copy(@DIR_OPT)

    # COMING SOON
    # ss3 = sub2.addParser "tojson", {help: "convert a signed manifest to JSON"}
    # add_option_dict ss3, @TOJSON_OPTS

    return opts.aliases.concat [ name ]

  #----------

  do_sign : (payload, cb) ->
    esc = make_esc cb, "Command::do_sign"
    gargs =
      args:  [ "--sign", "--detach-sign", "-a", "-u", (@me.fingerprint true) ]
      stdin: new BufferInStream(new Buffer(payload, 'utf8'))
    await master_ring().gpg gargs, esc defer out
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
    rel_ignore = path.relative(@argv.dir, @signed_file()).split(path.sep).join('/')
    ignore     = if rel_ignore[...2] isnt '..' then ["/#{rel_ignore}"] else []
    return ignore

  #----------

  signed_file: -> @argv.input or @argv.output or path.join(@argv.dir, codesign.constants.defaults.FILENAME)

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

  process_probs: (probs, cb) ->
    ###
    outputs warning and errors based on strict/quiet settings,
    and calls back with error if appropriate
    ###
    err_table  = (p for p in probs when (p[0] >= 100) or @argv.strict)
    warn_table = (p for p in probs when (p[0] <  100) and (not @argv.strict) and (not @argv.quiet))
    err        = null
    if warn_table.length
      log.warn "#{p[0]}\t#{p[1].expected?.path or p[1].got.path}:  #{p[1].msg}" for p in warn_table
    if err_table.length
      log.error "#{p[0]}\t#{p[1].expected?.path or p[1].got.path}:  #{p[1].msg}" for p in err_table
      unless @argv.ignore_verify_errors
        err = new Error "Exited after #{err_table.length} error(s)"
    cb err, {warnings: warn_table.length, errors: err_table.length}

  #----------

  keybase_username_from_signer: (s, cb) ->
    rxx = /^https:\/\/keybase.io\/([^\s\n]+)$/g
    if (m = rxx.exec s)?
      cb null, m[1]
    else
      cb new Error 'Could not extract a keybase username from signer'

  #----------

  verify: (cb) ->
    log.debug "+ Command::verify"
    esc = make_esc cb, "Command::verify"

    # 0. Init the verification engine
    eng = new MyEngine { @argv }
    await eng.global_init esc defer()

    # 1. load signed file
    await @target_file_to_json @signed_file(), esc defer json_obj

    if not json_obj?
      err = new E.NotFoundError "Could not open #{@signed_file()}"
      await athrow err, esc defer()

    # 2. make sure signature matches
    payload = codesign.CodeSign.json_obj_to_signable_payload json_obj
    for {signature, signer} in json_obj.signatures
      await @keybase_username_from_signer signer, esc defer username
      # console.log [payload,signature].join "\n-----------\n"
      await eng.run1 { payload, username, signature }, esc defer()

    # 2b --- cleanup the verification engine
    await eng.global_cleanup defer err_dummy

    # 3. walk and handle
    summ = new codesign.CodeSign @argv.dir, {ignore: json_obj.ignore, presets: json_obj.presets}
    await summ.walk esc defer()
    await summ.compare_to_json_obj json_obj, defer probs
    await @process_probs probs, esc defer {warnings}
    if not @argv.quiet
      log.info  "Success! " +
        json_obj.signatures.length + " signature(s) verified;" +
        " #{json_obj.found.length} items checked" +
        if warnings then " with #{warnings} warning(s); pass --strict to prevent success on warnings; --quiet to hide warnings" else ''

    log.debug "- Command::verify"
    cb()
  
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
    await @target_file_to_json @signed_file(), defer old_err, old_obj
    if old_obj?
      await cs.compare_to_json_obj old_obj, defer probs
      if not probs.length
        log.info "Found existing #{@signed_file()}" unless @argv.quiet
        for {signer, signature} in old_obj.signatures when signer isnt my_username
          cs.attach_sig signer, signature
          log.info "Re-attaching still-valid signature from #{signer}"
      else
        log.info "Will replace existing/obsolete #{@signed_file()}" unless @argv.quiet
 
    #
    # attach our own signature
    #
    # console.log "SIGNED PAYLOAD:\n-----\n#{cs.signable_payload()}\n---------"
    await @do_sign cs.signable_payload(), esc defer sig
    cs.attach_sig my_username, sig

    #
    # output
    #
    json_obj = cs.to_json_obj()
    md = codesign.obj_to_markdown json_obj
    await fs.writeFile @signed_file(), md, {encoding: 'utf8'}, esc defer()

    log.info  "Success! Wrote #{@signed_file()} from #{json_obj.found.length} found items" unless @argv.quiet
    log.debug "- Command::sign"
    cb()

  #----------

  run : (cb) ->
    #console.log @argv
    esc = make_esc cb, "Command::run"
    log.debug "+ Command::run"
    switch @argv.dir_subcommand
      when 'sign'   then await @sign   esc defer()
      when 'verify' then await @verify esc defer()
      when 'tojson' then await @tojson esc defer()
    log.debug "- Command::run"
    cb null

##=======================================================================

