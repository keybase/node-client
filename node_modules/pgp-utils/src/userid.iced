
#=================================================================================

exports.parse = (input) -> 
  components = null
  x = ///
    ^([^(<]*?)        # The beginning name of the user (no comment or key)
    (?:\s*\((.*?)\))? # The optional comment
    (?:\s*<(.*?)>)?$  # The optional email address
    ///
  if (m = input.match x)?
    components = 
      username : m[1]
      comment : m[2]
      email : m[3]
  return components

#=================================================================================

exports.format = (d) ->
  parts = [ ]
  if d.username?.length then parts.push d.username
  if d.comment?.length then parts.push "(" + d.comment + ")"
  if d.email?.length then parts.push "<" + d.email + ">"
  parts.join(' ')

#=================================================================================

