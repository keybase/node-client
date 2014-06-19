
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

exports.do_empty_build = (T,cb) ->
  sorted_map = new SortedMap { list : [] }
  await mem_tree.build { sorted_map }, defer err
  T.no_error err
  cb()
  
#===============================================================

exports.upsert_all = (T,cb) ->
  last = null
  for key,val of kvpairs
    await mem_tree.upsert { key, val }, defer err, new_root_hash
    T.no_error err

    new_root_node = mem_tree.get_root_node()
    new_root_hash_2 = mem_tree.hash_fn new_root_node.obj_s
    T.equal new_root_hash_2, new_root_hash, "Got the right hash back"
    if last?
      T.equal new_root_node.obj.prev_root, last, "Prev pointer was correct"
    last = new_root_hash 

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
