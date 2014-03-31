
##=======================================================================

exports.colgrep = colgrep = ({patterns, buffer, separator}) ->
  separator or= /:/
  lines = buffer.toString('utf8').split '\n'
  indices = (parseInt(k) for k,v of patterns)
  max_index = Math.max indices... 
  out = []
  for line in lines when (cols = line.split separator)? and (max_index < cols.length)
    found = true
    for k,v of patterns
      unless cols[k].match v 
        found = false
        break
    out.push cols if found
  return out

##=======================================================================
