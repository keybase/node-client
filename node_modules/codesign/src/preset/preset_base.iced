fs             = require 'fs'
path           = require 'path'
constants      = require '../constants'

# =============================================================================
#
# A base class to derive presets from. Contains some helpful member functions
# too.
#
# =============================================================================

PresetBase = class PresetBase

  constructor: ->

  # ---------------------------------------------------------------------------

  handle: (root_dir, path_to_file, cb) ->
    ###
      root_dir is the base directory of what we're studying; we won't look above
      this for configuration files in most presets.

      cb() with NONE, DONT_IGNORE, or IGNORE
    ###
    throw new Error 'Preset::handle is a virtual function'
    cb constants.ignore_res.DONT_IGNORE

  # ---------------------------------------------------------------------------

  @parent_paths: (root_dir, path_to_file) ->
    ###
      returns an array of directory names, starting with
      the parent of path_to_file, and traversing up
      to root_dir; if path_to_file is a directory itself,
      should not include that. Example reply:
        [
          '/foo/root/car/3/'
          '/foo/root/car/'
          '/foo/root/'
        ]
    ###
    res               = []
    full_path_to_file = path.resolve root_dir, path_to_file
    rel_path_to_file  = path.relative root_dir, full_path_to_file

    parts = rel_path_to_file.split path.sep

    for i in [0...parts.length]
      res.push path.join root_dir, path.join.apply(this, parts[0...i])
    res.reverse()
    return res


  # ---------------------------------------------------------------------------

  @file_to_array: (f, cb) ->
    # returns an empty array if the file does not exist
    res = []
    await fs.readFile f, {encoding: 'utf8'}, defer err, body
    if body?
      res.push line for line in body.split /[\n\r]+/
    cb res

  # ---------------------------------------------------------------------------

# =============================================================================

module.exports = PresetBase