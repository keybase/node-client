path            = require 'path'
fs              = require 'fs'
crypto          = require 'crypto'
LockTable       = require('iced-utils').lock.Table
utils           = require './utils'
XPlatformHash   = require './x_platform_hash'
constants       = require './constants'
{item_types}    = require './constants'

# =============================================================================
#
# file_info 'some_path', (err, finfo) -> ...
#
#   calls back with a FileInfo object, which will expose:
#      - stat
#      - lstat
#      - hash()               <-- cb based, but with caching
#      - is_binary()          <-- cb based, but with caching
#      - is_executable_file() <-- returns true if a file (not dir) and user exec
#
# and uses an internal cache so it never repeats these lookups
# 
# =============================================================================

class FileInfo
  constructor: (full_path) ->
    @_BINARY_BYTE_STUDY = 8000 # this is how git does it
    @full_path          = full_path
    @err                = null
    @lstat              = null
    @stat               = null # a synonym for lstat for our purposes
    @_hash              = {}
    @_link_hash         = {}
    @_is_binary         = null
    @_dir_contents      = null
    @_locks             = new LockTable()
    @_init_done         = false
    @link               = null
    @possible_win_link  = null # this is set to a path if it appears to be a git-converted symlink
    @item_type          = null # dir, file, symlink etc.

  # ---------------------------------------------------------------------------

  init: (cb) ->
    await 
      fs.lstat  @full_path, defer @err, @lstat
    @stat = @lstat
    if not @err
      await @_x_platform_type_check defer()
    @_init_done = true
    cb()

  # ---------------------------------------------------------------------------

  check_init: ->
    if not @_init_done then throw new Error "Init not done on #{@full_path}"

  # ---------------------------------------------------------------------------

  hash: (alg, encoding, cb) ->
    @check_init()
    k = "#{alg}|#{encoding}"
    await @_locks.acquire k, defer(lock), true  
    if (not @err) and (not @_hash[k]?)
      h    = new XPlatformHash {alg, encoding}
      fd   = fs.createReadStream @full_path
      await h.hash fd, defer @err, @_hash[k]
    lock.release()
    cb @err, @_hash[k]

  # ---------------------------------------------------------------------------

  link_hash: (alg, encoding, cb) ->
    @check_init()
    k = "#{alg}|#{encoding}|link_hash"
    await @_locks.acquire k, defer(lock), true  
    if (not @err) and (not @_link_hash[k]?)
      await (new XPlatformHash {alg, encoding}).hash_str @link, defer err, @_link_hash[k]
    lock.release()
    cb @err, @_link_hash[k]

  # ---------------------------------------------------------------------------

  dir_contents: (cb) ->
    @check_init()
    await @_locks.acquire 'dir_contents', defer(lock), true
    if (not @err) and (not @_dir_contents?)
      await fs.readdir @full_path, defer @err, fnames
      if fnames? then @_dir_contents = (f for f in fnames when f isnt '.')
    lock.release()
    cb @err, @_dir_contents

  # ---------------------------------------------------------------------------

  get_link: ->
    @check_init()
    @link

  # ---------------------------------------------------------------------------

  is_binary: -> 
    @check_init()
    @_is_binary

  # ---------------------------------------------------------------------------

  is_user_executable_file: -> 
    @check_init()
    @lstat.isFile() and !!(parseInt(100,8) & @lstat.mode)

  # ---------------------------------------------------------------------------

  _x_platform_type_check: (cb) ->
    ###
    gets link if it's a symbolic link; however if it is a regular
    file with a single short line in the file, it will save that in
    'possible_win_link' for cross-platform warnings
    ###
    if @lstat.isSymbolicLink()
      await fs.readlink @full_path, defer @err, @link
      @item_type = item_types.SYMLINK
    else if @stat.isFile()
      @item_type = item_types.FILE
      await @_binary_check defer()
    else if @stat.isDirectory()
      @item_type = item_types.DIR

    # let's discover if it's a windows style link
    if (@item_type is item_types.FILE) and (@stat.size < constants.tweakables.WIN_SYMLINK_MAX_LEN) and (not @_is_binary)
      await fs.readFile @full_path, {encoding: 'utf8'}, defer @err, data
      data  = data.replace /(^[\s]*)|([\s]*$)/g, ''
      lines = data.split   /[\n\r]+/g
      if lines.length is 1
        @possible_win_link      = lines[0]
    cb()

  # ---------------------------------------------------------------------------

  _binary_check: (cb) ->
    await fs.open @full_path, 'r', defer @err, fd
    if not @err
      len = Math.min @stat.size, @_BINARY_BYTE_STUDY
      if not len
        @_is_binary = true
      else
        b   = new Buffer len
        await fs.read  fd, b, 0, len, 0, defer @err, bytes_read
        if bytes_read isnt len
          console.log "#Requested #{len} bytes of #{@full_path}, but got #{bytes_read}"
        @_is_binary = false
        for i in [0...b.length]
          if b.readUInt8(i) is 0
            @_is_binary = true
            break
      await fs.close fd, defer @err
    cb()


# =============================================================================

class InfoCollection

  # ---------------------------------------------------------------------------

  constructor: ->
    @_locks = new LockTable()
    @_cache = {} # keyed by file absolute path

  # ---------------------------------------------------------------------------

  get: (f, cb) ->
    f = path.resolve f
    await @_locks.acquire f, defer(lock), true
    if not @_cache[f]?      
      @_cache[f] = new FileInfo f
      await @_cache[f].init defer()
    lock.release()
    cb @_cache[f].err, @_cache[f]

  # ---------------------------------------------------------------------------

ic = new InfoCollection()

# =============================================================================

module.exports = (f, cb) -> ic.get f, cb