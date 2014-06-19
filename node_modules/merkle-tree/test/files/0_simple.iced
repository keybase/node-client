
main = require '../../lib/main'
{ObjFactory} = require './obj_factory'
{Config,MemTree,SortedMap} = main
mem_tree = null
config = null
obj_factory = new ObjFactory()

#===============================================================

exports.init = (T,cb) ->
  config = new Config { N : 4, M : 16 }
  mem_tree = new MemTree { config }
  cb()

#===============================================================

do_inserts = (T,cb) ->
  for i in [0...1024]
    {key, val} = obj_factory.produce()
    await mem_tree.upsert { key, val }, defer err
    T.no_error err
  cb()
  
#===============================================================

exports.do_inserts_1 = (T,cb) -> do_inserts T,cb

#===============================================================

find_all = (T,cb) ->
  for key,val of obj_factory.dump_all()
    await mem_tree.find { key, skip_verify : false }, defer err, val2
    T.no_error err
    T.equal val, val2, "worked for key #{key}"
  cb()

#===============================================================

exports.find_all_1 = (T,cb) -> find_all T,cb

#===============================================================

exports.do_build = (T,cb) ->
  mem_tree = new MemTree { config }
  obj = obj_factory.dump_all()
  sorted_map = new SortedMap { obj }
  await mem_tree.build { sorted_map }, defer err
  T.no_error err
  cb()

#===============================================================

exports.find_all_2 = (T,cb) -> find_all T,cb

#===============================================================

exports.do_inserts_2 = (T,cb) -> do_inserts T,cb

#===============================================================

exports.find_all_3 = (T,cb) -> find_all T,cb

#===============================================================

exports.update_all = (T,cb) ->
  obj_factory.modify_some 2
  for key,val of obj_factory.dump_all()
    await mem_tree.upsert { key, val }, defer err, new_root_hash
    T.no_error err
  cb()

#===============================================================

exports.find_all_4 = (T,cb) -> find_all T,cb

#===============================================================
