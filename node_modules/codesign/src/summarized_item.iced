path              = require 'path'
{make_esc}        = require 'iced-error'
constants         = require './constants'
{item_types}      = require './constants'
utils             = require './utils'
XPlatformHash     = require './x_platform_hash'
finfo_cache       = require './file_info_cache'

# =====================================================================================================================

exports.SummarizedItem = class SummarizedItem

  constructor: ({parent_path, fname, codesign, depth})  ->
    @parent_path      = parent_path
    @fname            = fname
    @codesign       = codesign
    @depth            = depth or 0
    @item_type        = null
    @realpath         = null
    @link             = null
    @contents         = null
    @finfo            = null
    @hash             = null
    @link_hash        = null
    @binary           = false

  # -------------------------------------------------------------------------------------------------------------------

  load_traverse: (cb) ->
    esc         = make_esc cb, "SummarizedItem::load"
    p           = path.join @codesign.root_dir, @parent_path, @fname
    @realpath   = path.resolve p
    await  finfo_cache @realpath, esc defer @finfo

    @item_type = @finfo.item_type
    @link      = @finfo.link
    @binary    = @finfo.is_binary()

    if @item_type is item_types.FILE
      await @finfo.hash constants.hash.ALG, constants.hash.ENCODING, esc defer @hash
    else if @item_type is item_types.DIR
      @contents  = []
      await @finfo.dir_contents esc defer fnames
      for f in fnames
        subpath = path.join @realpath, f
        await @codesign._should_ignore subpath, esc defer ignore
        if not ignore
          si = @subitem f
          await si.load_traverse esc defer()
          @contents.push si
        #else
        #  console.log "Ignoring #{subpath}..."
      @contents.sort (a,b) -> a.fname.localeCompare(b.fname, 'us')
    else if @item_type is item_types.SYMLINK
      await @finfo.link_hash constants.hash.ALG, constants.hash.ENCODING, esc defer @link_hash
    cb()

  # -------------------------------------------------------------------------------------------------------------------

  subitem: (f) ->
    new SummarizedItem {
      fname:        f 
      parent_path:  if @parent_path.length then "#{@parent_path}/#{@fname}" else @fname 
      codesign:     @codesign
      depth:        @depth + 1
    }

  # -------------------------------------------------------------------------------------------------------------------

  obj_info: ->
    ###
    anything NOT preceeded with an underscore is expected to survive a serialization/deserialization
    for signing and loading.
    ###
    info =
      parent_path:    @parent_path
      item_type:      @item_type
      fname:          @fname
      path:           if @parent_path.length then "#{@parent_path}/#{@fname}" else @fname
      exec:           @finfo.is_user_executable_file()
      _depth:         @depth

    switch @item_type
      when item_types.FILE
        info.hash                = @hash
        info.size                = @finfo.lstat.size
        info._possible_win_link  = @finfo.possible_win_link
      when item_types.SYMLINK
        info.link                = @link
        info._link_hash          = @link_hash

    return info

  # -------------------------------------------------------------------------------------------------------------------

  walk_to_array: (_res)->
    ###
    returns an array of all items starting at this point,
    sorted in a predictable way; 
    ###
    _res or= []
    if @item_type is item_types.DIR
      _res.push @obj_info()
      c.walk_to_array(_res) for c in @contents
    else
      _res.push @obj_info()
    return _res
