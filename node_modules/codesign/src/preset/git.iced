path           = require 'path'
constants      = require '../constants'
PresetBase     = require './preset_base'
GlobberPreset  = require './globber'

# =======================================================================================

class GitPreset extends PresetBase

  constructor: ->
    @globbers = {}

  # -------------------------------------------------------------------------------------

  handle: (root_dir, path_to_file, cb) ->
    paths     = PresetBase.parent_paths root_dir, path_to_file
    res       = constants.ignore_res.NONE

    # ignore .git folders no matter what
    if path.basename(path_to_file) is '.git'
      res = constants.ignore_res.IGNORE

    # otherwise glob it upward to the root_dir
    else
      for p in paths
        await @get_globber p, defer globber
        await globber.handle root_dir, path_to_file, defer res
        if res isnt constants.ignore_res.NONE
          break
    cb res

  # -------------------------------------------------------------------------------------

  get_globber: (p, cb) ->
    if not @globbers[p]?
      fpath = path.join p, '.gitignore'
      await GlobberPreset.from_file fpath, defer @globbers[p]
    cb @globbers[p]

  # -------------------------------------------------------------------------------------

# =======================================================================================

module.exports = GitPreset