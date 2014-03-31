
path = require 'path'
fs   = require 'fs'

##=======================================================================

exports.mkdir_p = mkdir_p = (d, mode = 0o755, cb) ->
  parts = d.split path.sep
  cwd = [ ]
  if (parts.length and (parts[0].length is 0)) then cwd.push path.sep
  err = null
  made = 0

  for p in parts when not err?
    cwd.push p
    d = path.join.apply null, cwd
    await fs.stat d, defer err, so
    if err? and (err.code is 'ENOENT')
      await fs.mkdir d, mode, defer err
      made++ unless err?
    else if not err? and so? and not so.isDirectory()
      err = new Error "Path component #{d} isn't a directory"
  cb err, made
  
##=======================================================================

exports.rm_r = rm_r = (d, cb) ->
  await fs.readdir d, defer err, files
  unless err?
    for file in files when not (file in [".", ".."])
      full = path.join(d, file)
      await fs.stat full, defer err, stat
      if err? then #noop
      else if stat.isDirectory()
        await rm_r full, defer err
      else 
        await fs.unlink full, defer err
      break if err?
  unless err?
    await fs.rmdir d, defer err
  cb err

##=======================================================================

