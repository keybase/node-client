
Base = require('argparse').ArgumentParser
{rmkey} = require '../util'

##========================================================================

copy = (d1) ->
  d2 = {}
  d2[k] = v for k,v of d1
  return d2

##========================================================================

exports.add_option_dict = add_option_dict =  (ap, d) ->
  for k,v of d
    add_option_kv ap,k,v

#-------------

exports.add_option_kv = add_option_kv = (ap, k, d)->
  d = copy d
  names = [ k ]
  names.push a if (a = rmkey d, 'alias')
  names = names.concat as if (as = rmkey d, 'aliases')
  names = ("-#{if n.length > 1 then '-' else ''}#{n}" for n in names)
  ap.addArgument names, d

##========================================================================

