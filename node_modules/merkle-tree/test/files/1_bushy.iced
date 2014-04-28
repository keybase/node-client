
main = require '../../lib/main'
{ObjFactory} = require './obj_factory'
{Config,MemTree,SortedMap} = main
mem_tree = null
config = null
{sprintf} = require 'sprintf'

kvpairs = {}

#===============================================================

make_kvpairs = () ->

  for i in [0...(256*4)]
    a = (i % 256)
    b = (i >> 8)
    key = sprintf("%02x00%02x", a, b)
    val = [ i, key ]
    kvpairs[key] = val

#===============================================================

exports.init = (T,cb) ->
  config = new Config { N : 256, M : 256 }
  mem_tree = new MemTree { config }
  make_kvpairs()
  cb()

#===============================================================

exports.do_build = (T,cb) ->
  sorted_map = new SortedMap { obj : kvpairs }
  await mem_tree.build { sorted_map }, defer err
  T.no_error err
  cb()
  
#===============================================================

find_all = (T,cb) ->
  for key,val of kvpairs
    await mem_tree.find { key, skip_verify : false }, defer err, val2
    T.no_error err
    T.equal val, val2, "worked for key #{key}"
  cb()

#===============================================================

exports.find_all_1 = (T,cb) -> find_all T,cb

#===============================================================

exports.update_1 = (T,cb) ->
  key = "440002" 
  val = kvpairs[key]
  T.equal val, [580, key], 'value was as expected'
  val.push "extra"
  await mem_tree.upsert { key, val }, defer err
  T.no_error err
  cb()

#===============================================================

exports.find_all_2 = (T,cb) -> find_all T,cb

#===============================================================

exports.update_2 = (T,cb) ->
  key = "440010" 
  val = [1025, key ]
  kvpairs[key] = val
  await mem_tree.upsert { key, val }, defer err
  T.no_error err
  cb()

#===============================================================

exports.find_all_3 = (T,cb) -> find_all T,cb

#===============================================================
