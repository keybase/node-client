
#-----------------------------------------------------------------
#
# Given a block of unstructure text, extra the longest base64 blocks we can find.
# Return a list of them
#
exports.base64_extract = base64_extract= (text) -> 
  # for either web64 or standard 64, here is our total alphabet
  b64x = /^[a-zA-Z0-9/+_-]+(=*)$/
  tokens = text.split /\s+/
  state = 0
  out = []
  curr = []

  hit_non_b64 = () ->
    if curr.length 
      out.push(curr.join(''))
      curr = []
  hit_b64 = (tok) ->
    curr.push(tok)

  for tok in tokens
    if (tok.match b64x) then hit_b64(tok)
    else hit_non_b64()
  hit_non_b64()

  return out

#-----------------------------------------------------------------
