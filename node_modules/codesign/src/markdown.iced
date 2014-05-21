path         = require 'path'
tablify      = require 'tablify'
constants    = require './constants'
{item_types} = require './constants'
utils        = require './utils'

###

  A serializer/deserialized for Markdown from codesign objects.

  We can switch to jison if basic regexp-style parsing gets out of hand

###

# ======================================================================================================================

HEADINGS      = ['size', 'exec', 'file', 'contents']
SPACER        = '  '
TABLIFY_OPTS  =
  show_index:     false
  row_start:      ''
  row_end:        ''
  spacer:         SPACER
  row_sep_char:   ''

# ======================================================================================================================

hash_to_str   = (h) -> if h.hash is h.alt_hash then h.hash else "#{h.hash}|#{h.alt_hash}"

hash_from_str = (s) ->
  hashes = s.split '|'
  return {hash: hashes[0], alt_hash: hashes[1] or hashes[0]}

max_depth = (found_files) ->
  max_depth = 0
  max_depth = Math.max(f._depth, max_depth) for f in found_files
  max_depth

pretty_format_files = (found_files) ->
  rows = [HEADINGS]
  for f in found_files
    c0 = if (f.item_type is item_types.FILE) then f.size else ''
    c1 = if f.exec then 'x' else ''
    c2 = ("  " for i in [0...f._depth]).join('') + utils.escape f.fname # "#{f.path}"
    if f.item_type is item_types.DIR then c2 += "/"
    c3 = switch f.item_type
      when item_types.SYMLINK then "-> #{utils.escape(f.link)}"
      when item_types.DIR     then ''
      when item_types.FILE
        if (f.hash.hash is f.hash.alt_hash) or f.binary
          f.hash.hash 
        else
          "#{f.hash.hash}|#{f.hash.alt_hash}"
    rows.push [ c0, c1, c2, c3 ]
  return tablify rows, TABLIFY_OPTS

files_from_pretty_format = (str_arr) ->
  res               = []
  r0                = str_arr[0] 
  dir_queue         = []
  last_indent_level = 0

  [a0, b0] = [r0.indexOf(HEADINGS[0]), r0.indexOf(HEADINGS[1]) - SPACER.length]
  [a1, b1] = [r0.indexOf(HEADINGS[1]), r0.indexOf(HEADINGS[2]) - SPACER.length]
  [a2, b2] = [r0.indexOf(HEADINGS[2]), r0.indexOf(HEADINGS[3]) - SPACER.length]
  [a3, b3] = [r0.indexOf(HEADINGS[3]), r0.length]

  for s in str_arr[1...]
    c0 = s[a0...b0].replace /(^\s+)|(\s+$)/g, ''
    c1 = s[a1...b1].replace /(^\s+)|(\s+$)/g, ''
    c2 = s[a2...b2].replace /(^\s+)|(\s+$)/g, ''
    c3 = s[a3...b3].replace /(^\s+)|(\s+$)/g, ''
    indent_level      = s[a2...b2].match(/[^\s]/).index / SPACER.length
    fname             = utils.unescape(c2).replace /\/?$/,''    
    if (idiff = last_indent_level - indent_level) > 0
      dir_queue.pop() for i in [0...idiff]
    last_indent_level = indent_level
    parent_path       = dir_queue.join '/'
    info =
      fname:          fname
      parent_path:    parent_path
      path:           if parent_path.length then "#{parent_path}/#{fname}" else fname
      exec:           false
    if c3 is ''
      info.item_type = item_types.DIR
      dir_queue.push fname
      last_indent_level += 1
    else if c3[0...2] is '->'
      info.item_type = item_types.SYMLINK
      info.link      = utils.unescape c3[3...]
    else
      info.hash      = hash_from_str c3
      info.item_type = item_types.FILE
      info.size      = parseInt c0
      info.exec      = c1 is 'x'
    res.push info
  res

format_signature = (s) ->
  """
  ##### Signed by #{s.signer}
  ```
  #{s.signature}
  ```
  """

parse_signatures = (sig_region) ->
  res = []
  rxx = ///
    \#\#\#\#\#\sSigned\sby\s([^\n\r\s]*)
    \s*
    ```([^`]*)```
    \s*
  ///g
  while (match = rxx.exec sig_region)
    res.push {
      signer:    match[1].replace(/(^[\s]*)|([\s]*$)|(\r)/g, '')
      signature: match[2].replace(/(^[\s]*)|([\s]*$)|(\r)/g, '')
    }
  return res

footer = (o) -> 
  ns = o.signatures.length
  if ns isnt 1
    msg = "#{ns} signatures attached are valid"
    poss = "signers'"
  else
    msg = "signature attached is valid"
    poss = "signer's"
  return """
<hr>

#### Notes

With keybase you can sign any directory's contents, whether it's a git repo,
source code distribution, or a personal documents folder. It aims to replace the drudgery of:

  1. comparing a zipped file to a detached statement
  2. downloading a public key
  3. confirming it is in fact the author's by reviewing public statements they've made, using it

All in one simple command:

```bash
keybase dir verify
```

There are lots of options, including assertions for automating your checks.

For more info, check out https://keybase.io/docs/command_line/code_signing
"""

# ======================================================================================================================

exports.to_md = (o) ->

  ignore_list = (utils.escape s for s in o.ignore).join '\n'
  file_list   = pretty_format_files o.found
  preset_list = tablify ([p, "# #{constants.presets[p]}"] for p in o.presets), TABLIFY_OPTS
  signatures  = (format_signature s for s in o.signatures).join '\n\n'

  res = 
  """
#{signatures}

<!-- END SIGNATURES -->

### Begin signed statement 

#### Expect

```
#{file_list}
```

#### Ignore

```
#{ignore_list}
```

#### Presets

```
#{preset_list}
```

<!-- summarize version = #{o.meta.version} -->

### End signed statement

#{footer o}
  """

  return res

# ======================================================================================================================

exports.from_md = (str) ->
  rxx = ///
  ^ 
  \s*
  ([^\<]*)
  \s*
  \<\!--\sEND\sSIGNATURES\s--\>
  \s*
  \#\#\# \s Begin\ssigned\sstatement
  \s*
  \#\#\#\# \s Expect
  \s*
  ```([^`]*)```
  \s*
  \#\#\#\# \s Ignore
  \s*
  ```([^`]*)```  
  \s*
  \#\#\#\# \s Presets
  \s*
  ```([^`]*)```
  \s*
  \<\!--[\s]*summarize[\s]*version[\s]*=[\s]*([0-9a-z\.]*)[\s]*-->
  \s*
  \#\#\# \s End\ssigned\sstatement
  \s*
  [\s\S]*
  \s*
  $
  ///
  match  = rxx.exec str
  if match?
    signatures  = match[1]
    file_rows   = match[2].split(/\r?\n/)[1...-1] # formatting correction
    ignore_rows = match[3].split(/\r?\n/)[1...-1] # formatting correction
    preset_rows = match[4].split(/\r?\n/)[1...-1] # formatting correction
    version     = match[5]
    preset_rows = (f.replace /\s*(\#.*)?\s*$/g , '' for f in preset_rows)
    return {
      found:   files_from_pretty_format file_rows
      ignore:  (f for f in ignore_rows when f.length)
      presets: preset_rows
      meta:
        version: version
      signatures: parse_signatures signatures
    }
  else
    return null

# =====================================================================================================================