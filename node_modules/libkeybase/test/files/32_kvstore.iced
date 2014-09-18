

top = require '../..'
{Base,FlatMemory,Memory} = top.kvstore 
{E} = top.err

# Turn this on for debugging output...
#log = require 'iced-logger'
#log.package().env().set_level(0)

#========================================================

OBJS = [
  { type : "a", key : "1", value : "a1", name : "name-a1" },
  { type : "a", key : "2", value : "a1a2", name : "name-a2" },
  { type : "a", key : "3", value : "a1a2a3", name : "name-a3" },
  { type : "b", key : "1", value : "b1", name : "name-b1" },
  { type : "b", key : "2", value : "b1b2", name : "name-b2" },
  { type : "b", key : "3", value : "b1b2b3", names : [ "name-b3" ] },
]

#========================================================

class Tester

  constructor : ({@T, klass}) ->
    @obj = new klass()
    @name = klass.name

  test : (cb) ->
    await @open defer()
    await @puts defer()
    await @gets defer()
    await @lookups defer()
    await @relink defer()
    await @unlink defer()
    await @resolve defer()
    await @remove defer()
    await @unlink_all defer()
    await @close defer()
    await @nuke defer()
    cb null

  close : (cb) ->
    await @obj.close {}, defer err
    @T.waypoint "close"
    @T.no_error err
    cb()

  nuke : (cb) ->
    await @obj.nuke {}, defer err
    @T.waypoint "nuke"
    @T.no_error err
    cb()

  open : (cb) ->
    await @obj.open {}, defer err
    @T.waypoint "open"
    @T.no_error err
    cb()

  puts : (cb) ->
    for o in OBJS
      await @obj.put o, defer err
      @T.no_error err
    await @obj.put { key : "aabb03", value : "value-aabb03" }, defer err
    @T.no_error err
    @T.waypoint "puts"
    cb()

  gets : (cb) ->
    for o,i in OBJS
      await @obj.get o, defer err, value
      @T.no_error err
      @T.equal value, o.value, "get test object #{i}"
    await @obj.get { type : "03", key : "aabb03" }, defer err, value
    @T.no_error err
    @T.equal value, "value-aabb03", "fetch of implicit type worked"
    @T.waypoint "gets"
    cb()

  lookups : (cb) ->
    for o,i in OBJS
      o.name = o.names[0] unless o.name?
      await @obj.lookup o, defer err, value
      @T.no_error err
      @T.equal value, o.value, "lookup test object #{i}"
    @T.waypoint "lookups"
    cb()

  relink : (cb) ->
    await @obj.link { type : "a", name : "foob", key : "1" }, defer err
    @T.no_error err
    await @obj.lookup { type : "a", name : "foob" }, defer err, value
    @T.no_error err
    @T.equal value, "a1", "relink worked (1)"
    await @obj.lookup { type : "a", name : "name-a1" }, defer err, value
    @T.no_error err
    @T.equal value, "a1", "relink worked (2)"
    @T.waypoint "relink"
    cb()

  unlink : (cb) ->
    if @obj.can_unlink()
      await @obj.unlink { type : "a", name : "zooot" }, defer err
      @T.assert (err? and err instanceof E.LookupNotFoundError), "unlink fails on name not found"
    await @obj.unlink { type : "a", name : "foob" }, defer err
    @T.no_error err
    await @obj.lookup { type : "a", name : "name-a1" }, defer err, value
    @T.no_error err
    @T.equal value, "a1", "unlink left original link in place"
    await @obj.lookup { type : "a", name : "foob" }, defer err, value
    @T.assert not(value?), "no value after unlink"
    @T.assert (err? and err instanceof E.LookupNotFoundError), "right lookup error"
    @T.waypoint "unlink"
    cb()

  resolve : (cb) -> 
    await @obj.resolve { type : "a", name : "name-a3" }, defer err, key
    @T.no_error err
    @T.equal key, "3"
    @T.waypoint "resolve"
    cb()

  remove : (cb) ->
    # First try 2 failures to remove
    await @obj.remove { type : "a", key : "zoo" }, defer err
    @T.assert (err? and err instanceof E.NotFoundError), "right error on failed delete"
    await @obj.remove { type : "a", key : "zoo", optional : true }, defer err
    @T.no_error err

    await @obj.remove { type : "a" , key : "3" }, defer err
    @T.no_error err
    await @obj.get { type : "a", key : "3" }, defer err, value
    @T.assert not(value?), "No value should be found for a:3"
    @T.assert (err? and err instanceof E.NotFoundError), "NotFound for 'a:3'"
    await @obj.resolve { type : "a", name : "name-a3" }, defer err, key
    if @obj.can_unlink()
      @T.assert not(key?), "cannot resolve name 'name-a3'"
      @T.assert (err? and err instanceof E.LookupNotFoundError), "right lookup error"
    else
      @T.no_error err
      @T.equal key, "3", "still is there as a dangling pointer"
    @T.waypoint "remove"
    cb()

  unlink_all : (cb) ->
    await @obj.link { type : "b", key : "2", name : "cat" }, defer err
    @T.no_error err
    await @obj.link { type : "b", key : "2", name : "dog" }, defer err
    @T.no_error err
    if @obj.can_unlink()
      await @obj.unlink_all { type : "b", key : "cat" }, defer err
      @T.assert (err? and err instanceof E.LookupNotFoundError), "can't unlink what's not there"
    await @obj.unlink_all { type : "b", key : "2" }, defer err
    @T.no_error err
    cb()

#========================================================

test_store = ({T,klass},cb) ->
  tester = new Tester { T, klass }
  await tester.test defer()
  cb()

exports.test_flat_memory = (T,cb) ->
  await test_store { T, klass : FlatMemory }, defer()
  cb()

exports.test_memory = (T,cb) ->
  await test_store { T, klass : Memory }, defer()
  cb()

exports.test_base = (T,cb) ->
  abstracts = [ 
    "open", "nuke", "close", "_unlink", "_unlink_all", 
    "_remove", "_put", "_get", "_resolve", "_link" 
  ]
  b = new Base {}
  for method in abstracts
    await b[method] {}, defer err
    T.assert (err? and err instanceof E.UnimplementedError), "method #{method} failed"
  cb()
