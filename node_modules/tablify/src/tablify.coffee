
# --------------------------------------------------------------------------------
# This is the likely function you want to use.
# "arr" can be:
#     1. an array of arrays (a.k.a. "AoA")
#     2. or an array of dicts (a.k.a. "AoD")
#     3. or a single dictionary (a.k.a. "asD")
#
#  options and defaults, depending on type of rows
#
#     has_header:   AoA: default = false; when true, shows first row separated
#                   AoD: default = true;  when true, uses keys as column heads
#                   asD: ignored
#     show_index:   default = false; adds an extra column showing row number
#     keys:         AOD: default = null; if set, only show these cols
#     row_start     default = "| "
#     row_end       default = " |"
#     spacer        default = " | "
#     row_sep_char  default = "_"
# --------------------------------------------------------------------------------

exports = module.exports = (arr, opts) ->
  if (typeof arr) is 'object'
    if not Array.isArray arr
      return exports.tablifySingleDict arr, opts
    else if isArrayOfArrays arr
      return exports.tablifyArrays arr, opts
    else
      return exports.tablifyDicts arr, opts
  else throw new Error 'tablify cannot handle non-objects'

exports.tablify = exports

# --------------------------------------------------------------------------------

exports.tablifySingleDict = (o, opts) ->
  arr = []
  for k,v of o
    arr.push [k,v]
  arr.sort (r1, r2) -> r1[0].localeCompare r2[0]
  return exports.tablifyArrays arr, opts

# --------------------------------------------------------------------------------

exports.tablifyArrays = (arr, opts) ->
  c = new printer opts
  c.push row for row in arr
  c.stringify()

# --------------------------------------------------------------------------------

exports.tablifyDicts = (arr, opts) ->
  ###
  takes an array of dictionaries that may have different keys
  ###
  opts = opts or {}
  if not opts.has_header? then opts.has_header = true
  if not opts.show_index? then opts.show_index = true
  if not opts.keys
    known_keys = {}
    for dict in arr
      known_keys[k] = true for k of dict
    opts.keys = (k for k of known_keys)
    opts.keys.sort()
  c = new printer opts
  if opts.has_header
    row = (k for k in opts.keys)
    c.push row
  for dict,i in arr
    row = []
    for k in opts.keys
      row.push (if dict[k]? then dict[k] else null)
    c.push row
  c.stringify()

# --------------------------------------------------------------------------------


class printer
  constructor: (opts) ->
    @opts               = opts or {}
    @opts.spacer        = if @opts.spacer? then @opts.spacer else " | "
    @opts.row_start     = if @opts.row_start? then @opts.row_start else  "| "
    @opts.row_end       = if @opts.row_end? then @opts.row_end else " |"
    @opts.row_sep_char  = if @opts.row_sep_char? then @opts.row_sep_char else "-"
    @opts.has_header    = if @opts.has_header? then @opts.has_header else false
    @opts.show_index    = if @opts.show_index? then @opts.show_index else false
    @rows               = []
    @col_widths         = []

    if @opts.border == false
      opts.spacer = ' '
      @opts.row_start = @opts.row_end = @opts.row_sep_char = ''

  push: (row_to_push) ->
    row = (cell for cell in row_to_push)
    if @opts.show_index
      row_num = @rows.length
      if @opts.has_header then row_num--
      if row_num < 0
        row.splice 0,0,"#"
      else
        row.splice 0,0,row_num
    @rows.push row
    for cell, i in row
      if (not @col_widths[i]?) or (@col_widths[i] < @len cell)
        @col_widths[i] = @len cell

  stringify: ->

    strs        = []
    total_width = @opts.row_start.length + @opts.row_end.length
    total_width += width for width in @col_widths
    total_width += @opts.spacer.length * (@col_widths.length - 1)

    if @opts.row_sep_char.length
      strs.push @chars @opts.row_sep_char, total_width

    for row, j in @rows
      line = @opts.row_start
      for width, i in @col_widths
        line += @ljust (if row[i]? then row[i] else ""), width
        if i < @col_widths.length - 1
          line += @opts.spacer
      line += @opts.row_end
      strs.push line

      if @opts.row_sep_char
        if (j is 0) and @opts.has_header
          strs.push @chars @opts.row_sep_char, total_width

    if @opts.row_sep_char.length
      strs.push @chars @opts.row_sep_char, total_width

    return strs.join "\n"

  toStr: (o) -> 
    if o is null then                       return "null"
    else if (typeof o) is "undefined" then  return ""
    else if (typeof o) is "object"
      try
                                            return JSON.stringify o
      catch e
                                            return "[#{e.message}]"
    else                                    return o.toString()

  len:   (o) -> @toStr(o).length
  chars: (c, num) -> (c for i in [0...num]).join ""
  ljust: (o, num) -> "#{@toStr o}#{@chars ' ', (num - @len o)}"
  rjust: (o, num) -> "#{@chars ' ', (num - @len o)}#{@toStr o}"

# --------------------------------------------------------------------------------

isArrayOfArrays = (arr) ->
  for x in arr
    if not (Array.isArray x)
      return false
  return true
