{constants} = require './constants'
{fullname} = require './package'
{request} = require './request'
log = require './log'
{tmpdir} = require 'os'
fs = require 'fs'
{chain,make_esc} = require 'iced-error'
iutils = require 'iced-utils'
{a_json_parse,base64u} = iutils.util
{mkdir_p} = iutils.fs
{prng} = require 'crypto'
path = require 'path'
{set_gpg_cmd,keyring} = require 'gpg-wrapper'
{AltKeyRing} = keyring
kpath = require 'keybase-path'

##==============================================================

url_join = (args...) ->
  rxx = /// ^(/*) (.*?) (/*)$ ///
  trim = (s) -> if (m = s.match(rxx))? then m[2] else s
  parts = (trim(a) for a in args)
  parts.join '/'

#==========================================================

home = (opts) ->
  x = kpath.home opts
  return x

#==========================================================

exports.Config = class Config

  #--------------------

  constructor : (@argv) ->
    @_tmpdir = null
    @_alt_cmds = {}
    @_keyring_dir = null
    @_actual_prefix = null

  #--------------------

  set_actual_prefix : (p) -> @_actual_prefix = p

  #--------------------

  get_keyring_dir : () ->
    unless @_keyring_dir?
      unless ((d = @argv.get("k", "keyring-dir"))?)
        v = (home { array : true }).concat [ ".keybase-installer", "keyring" ]
        d = kpath.unsplit v
      @_keyring_dir = d
    return @_keyring_dir

  #--------------------

  init_keyring : (cb) ->
    keyring.init {
      log : log,
      get_tmp_keyring_dir : () => @get_tmpdir()
      get_no_options : () => @get_no_gpg_options()
    }
    dir = @get_keyring_dir()
    esc = make_esc cb, "Config::init_keyring"
    await AltKeyRing.make dir, esc defer @_master_ring
    await @_master_ring.index esc defer @_keyring_index
    cb null

  #--------------------

  keyring_index : () -> @_keyring_index
  master_ring : () -> @_master_ring

  #--------------------

  set_master_ring : (r, cb) ->
    @_master_ring = r
    await @_master_ring.index defer err, @_keyring_index
    cb err

  #--------------------

  url_prefix : () ->
    if (u = @argv.get("u", "url-prefix")) then u
    else
      prot = if (@argv.get("S","no-https")) then 'http' else 'https'
      constants.url_prefix[prot]

  #--------------------

  install_prefix : () -> process.env.PREFIX or @argv.get("p", "prefix")

  #--------------------

  make_url : (u) -> url_join @url_prefix(), u

  #--------------------

  get_tmpdir : () -> @_tmpdir
  get_no_gpg_options : () -> @argv.get("O", "no-gpg-options")

  #--------------------

  make_tmpdir : (cb) ->
    err = null
    unless @_tmpdir?
      r = base64u.encode(prng(16))
      p = kpath.split(tmpdir()).concat [ "keybase_install_#{r}" ]
      @_tmpdir = kpath.unsplit p
      await fs.mkdir @_tmpdir, 0o700, defer err
      log.info "Made temporary directory: #{@_tmpdir}"
    cb err

  #------------

  cleanup : (cb) ->
    esc = make_esc cb, "Installer::cleanup"
    log.debug "+ cleanup #{@_tmpdir}"
    if not @_tmpdir? then # noop
    else if @argv.get("C","skip-cleanup")
      log.info "Preserving tmpdir #{@_tmpdir} as per command-line switch"
    else
      log.info "cleaning up tmpdir #{@_tmpdir}"
      await fs.readdir @_tmpdir, esc defer files
      for f in files
        p = kpath.join @_tmpdir, f
        log.debug "| Unlink #{p}"
        await fs.unlink p, esc defer()
      await fs.rmdir @_tmpdir, esc defer()
    log.debug "- cleanup #{@_tmpdir} -> OK"
    cb null

  #--------------------

  get_proxy : () ->
    @argv.get("x", "proxy") or process.env.https_proxy or process.env.http_proxy

  #--------------------

  request : (u, cb) ->
    url = if u.match("^https?://") then u else @make_url(u)
    opts =
      url : url
      headers : { "X-Keybase-Installer" : fullname() },
      maxRedirects : 10
      progress : 50000
      proxy : @get_proxy()
    log.info "Fetching URL #{url}"
    await request opts, defer err, res, body
    log.debug " * fetched -> #{res?.statusCode}"
    cb err, res, body

  #--------------------

  set_keys : (keys) ->
    if not @_keys? or @_keys.version isnt keys.version
      log.info "Using keyset version v#{keys.version}"
      @_keys = keys

  #--------------------

  set_alt_cmds : () ->
    @set_alt_gpg()
    @set_alt_npm()

  #--------------------

  set_alt_gpg : () ->
    if (c = @argv.get("g","gpg"))?
      @_alt_cmds.gpg = c
    else
      null

  #--------------------

  set_alt_npm : () ->
    if (n = @argv.get("n", "npm"))?
      @_alt_cmds.npm = n

  #--------------------

  get_alt_cmd : (k) -> @_alt_cmds[k]
  get_cmd     : (k) -> @get_alt_cmd(k) or k

  #--------------------

  key_version : () -> @_keys.version

  #--------------------

  set_index : (i) -> @_index = i
  index : () -> @_index

  #--------------------

  index_lookup_hash : (v) -> @_index.package?.all?[v]

  #--------------------

  oneshot_verify : ({which, sig, file}, cb) ->
    query = @_keys[which].fingerprint()
    await @master_ring().oneshot_verify {query, file, sig, single: true}, defer err, json
    cb err, json

#==========================================================

