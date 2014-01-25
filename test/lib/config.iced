
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

#===================================================

class Config

  DEFAULT_FILE : ".node_client_test.conf"

  #----------------

  constructor : ( { @file }) ->
    @_data =  {}

  #----------------

  init : (cb) ->
    esc = make_esc cb, "Config::init"
    await @open_config esc defer()
    cb null

  #----------------

  open_config : (cb) ->
    file = if @file then @file else path.join(home(),@DEFAULT_FILE)
    await fs.readFile file, defer err, data
    if not err?
      await a_json_parse data, defer err, @_data
      if err?
        log.error "#{file}: Error parsing json: #{err.message}"
    else if @file
      log.error "#{file}: cannot open config file: #{err.message}"
    else
      log.warn "No config file given, and none found in ~/#{@DEFAULT_FILE}; using defaults"
      err = null
    cb err

  #----------------

  scratch_dir : () ->
    @_data?.scratch or path.join(__dirname, "..", "scratch")

#====================================================================

_config = null
exports.init = (opts, cb) ->
  _config = new Config opts
  await _config.init defer err
  cb err

#----------------

exports.config = () -> _config

#====================================================================
