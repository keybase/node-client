
Base = require('argparse').ArgumentParser
{rmkey} = require '../util'

##========================================================================


exports.add_option_dict = add_option_dict =  (ap, d) ->
  for k,v of d
    add_option_kv ap,k,v

#-------------

exports.add_option_kv = add_option_kv = (ap, k, d)->
  names = [ "-#{k}" ]
  names.push "--#{a}" if (a = rmkey d, 'alias')?
  names = names.concat ("--#{a}" for a in as) if (as = rmkey d, 'aliases')?
  ap.addArgument names, d

##========================================================================

