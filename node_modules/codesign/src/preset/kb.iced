path           = require 'path'
constants      = require '../constants'
PresetBase     = require './preset_base'
GlobberPreset  = require './globber'

# =======================================================================================

class KbPreset extends PresetBase

  constructor: ->
    @globbers = {}

  # -------------------------------------------------------------------------------------

  handle: (root_dir, path_to_file, cb) ->
    paths     = PresetBase.parent_paths root_dir, path_to_file
    res       = constants.ignore_res.NONE

    for p in paths
      await @get_globber p, defer globber
      await globber.handle root_dir, path_to_file, defer res
      if res isnt constants.ignore_res.NONE
        break
    cb res

  # -------------------------------------------------------------------------------------

  get_globber: (p, cb) ->
    if not @globbers[p]?
      fpath = path.join p, '.kbignore'
      await GlobberPreset.from_file fpath, defer @globbers[p]
    cb @globbers[p]

  # -------------------------------------------------------------------------------------

# =======================================================================================

module.exports = KbPreset