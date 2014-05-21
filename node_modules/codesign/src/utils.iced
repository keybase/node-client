constants = require './constants'
tablify   = require 'tablify'

module.exports =
  escape: (s) ->
    ###
    we don't want to use either escape (deprecated) or encodeURIComponent (too ugly) and overescapes    
    ###
    res = ''
    for c, i in s
      if c.match /^[a-z0-9\/\._\-\~\#]$/i 
        res += c
      else
        res += encodeURIComponent(c).replace /%20/g, '+'
    return res

  unescape: (s) -> decodeURIComponent s.replace /\+/g, '%20'

  item_type_name: (it) ->
    switch it
      when constants.item_types.FILE then 'file'
      when constants.item_types.SYMLINK then 'symlink'
      when constants.item_types.DIR then 'directory'
      else throw new Error "Unknown type: #{it}"

  plain_tablify: (d, spaces=2) ->
    return tablify d, 
      show_index:     true
      row_start:      ''
      row_end:        ''
      spacer:         (' ' for i in [0...spaces]).join ''
      row_sep_char:   ''