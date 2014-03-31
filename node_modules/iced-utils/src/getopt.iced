
#======================================================================

class Result
  constructor : () ->
    @args = []
    @opts = {}

  get : (names...) ->
    if names.length is 0 then return @args
    else
      for name in names
        if (val = @opts[name])? then return val
      return null

#======================================================================

module.exports = getopt = (argv, { flags }) ->
  out = new Result
  i = 0
  while i < argv.length
    arg = argv[i]
    if arg is '--'
      out.args = argv[(i+1)...]
      break
    else if arg[0] isnt '-'
      out.args = argv[i...]
      break
    else if arg[0...2] is '--'
      if (name = arg[2...]) in flags
        out.opts[name] = true
        i++
      else
        out.opts[name] = argv[i+1]
        i +=2 
    else if arg[1] in flags
      for ch in arg[1...]
        out.opts[ch] = true
      i++
    else if arg.length is 2
      out.opts[arg[1...]] = argv[i+1]
      i += 2
    else
      out.opts[arg[1]] = arg[2...]
      i++

  return out

#======================================================================
