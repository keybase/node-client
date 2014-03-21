
{env} = require './env'
colors = require 'colors'

make_color = (c) ->
  exports[c] = (s) -> 
    if env().get_no_color() then s else colors[c](s)

for k,v of colors
  make_color(k)

