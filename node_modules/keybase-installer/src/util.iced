
{json_stringify_sorted} = require('iced-utils').util
{createHash} = require 'crypto'
{constants} = require './constants'

#===========================================================================

exports.strip = strip = (x) -> if (m = x.match(/^(\s*)(.*?)(\s*)$/)) then m[2] else x

#===========================================================================

exports.hash_json = (x) -> 
  createHash('SHA512').update(strip(json_stringify_sorted(x))).digest('hex')

#===========================================================================
