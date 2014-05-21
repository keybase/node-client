path           = require 'path'
constants      = require '../constants'
PresetBase     = require './preset_base'

# =======================================================================================
#
# This file's rules taken from
#   https://www.dropbox.com/help/145/en
#
# =======================================================================================


class DropboxPreset extends PresetBase

  handle: (root_dir, path_to_file, cb) ->
    basename = path.basename path.join root_dir, path_to_file
    res      = constants.ignore_res.NONE

    # KNOWN FILES TO SKIP
    if basename.toLowerCase() in [
      '.dropbox'
      '.dropbox.attr'
      '.dropbox.cache'
      'desktop.ini'
      'thumbs.db'
      '.ds_store'
      'ds_store'
      'icon\r'
    ] then res = constants.ignore_res.IGNORE

    # TEMP FILE PATTERNS DROPBOX SKIPS
    else if basename.match ///
      ^
      (\~\$.*)    | # begins with a ~$
      (\.\~.*)    | # begins with a .~
      (\~.*\.tmp)   # begins with ~ and ends with .tmp
      $
    ///gi then res = constants.ignore_res.IGNORE

    cb res

  # -------------------------------------------------------------------------------------

# =======================================================================================

module.exports = DropboxPreset