
#
# A configuration file manager for the test script.  The config
# file won't be checked in, but it will tell us how to access
# our test social media accounts.
#
#====================================================================

log = require '../../lib/log'
{home} = require '../../lib/path'
{make_esc} = require 'iced-error'
{a_json_parse} = require('iced-utils').util
path = require 'path'
fs = require 'fs'
gpg = require 'gpg-wrapper'
{keyring} = gpg
urlmod = require 'url'

#===================================================

class CycleList 

  constructor : (@v) ->
    @_i = 0

  get : () -> 
    ret = null
    if @v.length
      ret = @v[@_i]
      @_inc()
    return ret

  _inc : () ->
    @_i = (@_i + 1) % @v.length

#===================================================

class Config

  DEFAULT_FILE : ".node_client_test.json"

  #----------------

  DEFAULT_CONFIG :
    server : 
      host : "localhost"
      port : 3000
      no_tls : 1

  #----------------

  constructor : ( { @file, @debug, @uri }) ->
    @_data =  {}
    @_dummies = {}

  #----------------

  server_obj : () ->
    if (o = @_data?.server) then o
    else if not uri? then @DEFAULT_CONFIG.server
    else 
      u = urlmod.parse(@uri)
      {
        host : u.host
        port : u.port
        no_tls : (u.protocol is 'http:')
      }

  #----------------

  config_logger : () ->
    p = log.package()
    p.env().set_level p.DEBUG if @debug
    gpg.set_log log.warn

  #----------------

  init : (cb) ->
    esc = make_esc cb, "Config::init"
    await @open_config esc defer()
    @config_logger()
    keyring.init {
      log : log,
      get_debug : () => @debug
    }
    cb null

  #----------------

  keybase_cmd : (inargs) ->
    inargs.args = [ "-d" ].concat(inargs.args) if @debug
    inargs.name = path.join __dirname, "..", "..", "bin", "main.js"
    inargs.quiet = false if inargs.quiet and @debug
    return inargs

  #----------------

  open_config : (cb) ->
    file = if @file then @file else path.join(home(),@DEFAULT_FILE)
    await fs.readFile file, defer err, data
    if not err?
      await a_json_parse data, defer err, @_data
      if err?
        log.error "#{file}: Error parsing json: #{err.message}"
      else
        @load_dummy_accounts()
    else if @file
      log.error "#{file}: cannot open config file: #{err.message}"
    else
      log.warn "No config file given, and none found in ~/#{@DEFAULT_FILE}; using defaults"
      err = null
    cb err

  #----------------

  load_dummy_accounts : () ->
    if @_data.dummies?
      for k,v of @_data.dummies
        @_dummies[k] = new CycleList v

  #----------------

  scratch_dir : () ->
    @_data?.scratch or path.join(__dirname, "..", "scratch")

  #----------------

  get_dummy_account : (service_name) -> @_dummies?[service_name]?.get()


#====================================================================

_config = null
exports.init = (opts, cb) ->
  _config = new Config opts
  await _config.init defer err
  cb err

#----------------

exports.config = () -> _config

#====================================================================
