{createHash} = require 'crypto'
iutils = require 'iced-utils'
{mkdir_p,rm_r} = iutils.fs
{athrow,a_json_parse} = iutils.util
fs = require 'fs'
path = require 'path'
{make_esc} = require 'iced-error'
{E} = require './err'

#=============================================================================

hash = (x) ->
  h = createHash('SHA256')
  h.update(x)
  h.digest().toString('hex')

##=======================================================================

mkdir_p_2 = ({root, dirs, mode}, cb) ->
  err = null
  made = 0
  cwd = root

  for p in dirs when not err?
    cwd = [ cwd, p ].join path.sep
    await fs.stat cwd, defer err, so
    if err? and (err.code is 'ENOENT')
      await fs.mkdir cwd, mode, defer err
      made++ unless err?
    else if not err? and so? and not so.isDirectory()
      err = new Error "Path component #{cwd} isn't a directory"
  cb err, made

#=============================================================================

class DB

  #------------------------

  constructor : ( { @root, levels, json, dir_mode, file_mode } ) ->
    @levels =levels or 2
    @json = if json? then json else true
    @_path_prefix = @root.split path.sep
    @dir_mode = dir_mode or 0o755
    @file_mode = file_mode or 0o644

  #------------------------

  _key_to_hkey : (key) -> hash key

  #------------------------

  _key_to_dirs : (key) -> @_hkey_to_dirs @_key_to_hkey key

  #------------------------

  _keys_to_dirs : ({key, hkey}) ->
    if key? then @_key_to_dirs key
    else if hkey? then @_hkey_to_dirs hkey
    else null

  #------------------------

  _hkey_to_dirs : (hkey) ->
    out = [] 
    for i in [0...@levels]
      j = i * 2
      out.push hkey[j...(j+2)]
    out.push hkey
    return out

  #------------------------

  _mkpath : (dirs) ->
    top = if @_path_prefix?[0] is '' then [ path.sep ] else []
    p = top.concat(@_path_prefix).concat(dirs)
    path.join p...

  #------------------------

  _mkpath_from_key : (key) -> @_mkpath @_key_to_dirs key

  #------------------------

  _mkpath_from_hkey : (hkey) -> @_mkpath @_hkey_to_dirs hkey

  #------------------------

  _mkpath_from_keys : ( {key, hkey} ) ->
    if key? then @_mkpath_from_key key
    else if hkey? then @_mkpath_from_hkey hkey
    else null

  #------------------------

  create : (cb) ->
    await mkdir_p @root, @dir_mode, defer err, made
    cb err, made

  #------------------------

  drop : (cb) ->
    await rm_r @root, defer err
    cb err

  #------------------------

  put : ( { hkey, key, value, json }, cb) ->
    hkey or= @_key_to_hkey key
    dirs = @_hkey_to_dirs hkey
    file = dirs.pop()
    esc = make_esc cb, "Db::put"

    await mkdir_p_2 { @root, dirs : dirs, mode : @dir_mode }, esc defer()

    if (not(json?) and @json) or json
      value = JSON.stringify(value)

    err = null
    encoding = "binary"

    typ = typeof(value)
    if typ is 'object'
      if Buffer.isBuffer(value) 
        encoding = "binary"
      else
        err = new Error "Cannot put object"
    else if typ is 'string'
      value = new Buffer value, 'utf8'
      encoding = "utf8"
    else
      err = new Error "Cannot put value of type: #{typ}"

    await athrow err, esc defer() if err?

    f = @_mkpath dirs.concat([file])
    opts = { encoding, mode : @file_mode }
    await fs.writeFile f, value, opts, esc defer()

    cb err, { hkey }

  #------------------------

  get : ( { hkey, key, json }, cb ) ->
    value = null
    err = null
    f = @_mkpath_from_keys  { key, hkey }
    await fs.readFile f, defer err, buf
    if err? 
      if err.code is 'ENOENT'
        err = new E.NotFoundError "No data for key #{key}"
    else if (not(json?) and @json) or json
      await a_json_parse buf, defer err, value
      if err?
        err = new E.DecodeError err.message
    else
      value = buf
    cb err, value

  #------------------------

  del : ( { key, hkey }, cb ) ->
    f = @_mkpath_from_keys  { key, hkey }
    await fs.unlink f, defer err
    if err? and err.code is 'ENOENT'
      err = new E.NotFoundError "No data for key #{key}"
    cb err

#=============================================================================

exports.DB = DB

#=============================================================================

