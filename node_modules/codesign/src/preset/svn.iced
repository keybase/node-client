path           = require 'path'
constants      = require '../constants'
PresetBase     = require './preset_base'
GlobberPreset  = require './globber'

# =======================================================================================

class SvnPreset extends PresetBase

  constructor: ->
    @globbers = {}

  # -------------------------------------------------------------------------------------

  handle: (root_dir, path_to_file, cb) ->
    paths     = PresetBase.parent_paths root_dir, path_to_file
    res       = constants.ignore_res.NONE

    # ignore .svn folders no matter what
    if path.basename(path_to_file) is '.svn'
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
      command = 'svn proplist -v -R 2>/dev/null | grep -B 1 svn:ignore | grep -v "svn:ignore" | cut -d "\'" -f 2'
      await GlobberPreset.from_command p, command, defer @globbers[p]
    cb @globbers[p]

  # -------------------------------------------------------------------------------------

# =======================================================================================

module.exports = SvnPreset
