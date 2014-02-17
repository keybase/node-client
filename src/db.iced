
{env} = require './env'
{Database} = sqlite3
fs = require 'fs'
path = require 'path'
{chain,make_esc} = require 'iced-error'
{mkdirp} = require './fs'
{Lock} = require('iced-utils').lock
{util} = require 'pgp-utils'
log = require './log'
{constants} = require './constants'
Datastore = require 'nedb'

##=======================================================================

pair2str = (type, name) -> (type + ":" + name)
str2pair = (s) -> if (m = s.match /^([^:]+):(.*)?/)? then [ m[0], m[1] ] else s
dict2str = ({type,name}) ->
  type or= key[-2...]
  pair2str(type,key)

##=======================================================================

class DB

  constructor : ({@filename}) ->
    @lock = new Lock

  get_filename : () ->
    @filename or= env().get_db_filename()
    return @filename

  #----

  open : (cb) ->
    err = null
    await @_open defer err unless @db?
    cb err

  #----

  unlink : (cb) ->
    fn = @get_filename()
    log.info "Purging local cache: #{fn}"
    await fs.unlink fn, defer err
    cb err

  #----

  _open : (cb) ->
    esc = make_esc cb, "DB::open"
    err = null
    fn = @get_filename()
    log.debug "+ opening NEDB database file: #{fn}"
    await mkdirp fn, esc defer()
    @db = new Datastore { filename : @get_filename () }
    await @db.loadDatabase esc defer()
    await @_init_db esc defer()
    log.debug "- DB opened"
    cb null

  #-----

  put : ({type, key, value, name, names}, cb) ->
    docs = [ { key : dict2str({type, key}), value : value } ]

    if names and names.length
      for name in names
        docs.push { name : pair2str(name.type, name.name), name_to_key : pair2str(type,key) }

    await @db.insert docs, defer err
    cb err

  #-----

  remove : ({type, key}, cb) ->
    k = pair2str(type,key)
    log.debug "+ DB remove #{k}"
    esc = make_esc cb, "DB::remove"
    await @db.delete { key : k }, { mutli : true }, esc defer()
    await @db.delete { name_to_key : k }, { multi : true }, esc defer()
    log.debug "- DB remove #{k} -> ok"
    cb null

  #-----

  find1 : (q, cb) ->
    await @db.find q, defer err, docs
    err = value = null
    if err? then # noop
    else if (l = docs.length) is 0 then value = null
    else if l > 1 then err = new E.CorruptionError "Got #{s} docs back; only wanted 1"
    else value = docs[0].value
    cb err, value

  #-----

  get : ({type, key}, cb) ->
    k = dict2str { type,key }
    await @find1 { key : k }, defer err, value
    cb err, value

  #-----

  lookup : ({type, name}, cb) ->
    k = dict2str { type, key : name }
    err = value = null
    await @find1 { name : k }, defer err, value
    if value? and not err?
      await @find1 { key : value }, defer err, value
    cb err, value

  #-----

  _init_db : (cb) ->
    log.debug "+ DB::_init_db"
    esc = make_esc cb, "DB::_init_db"
    await @db.ensureIndex { fieldName : "key" , unique : true }, esc defer()
    await @db.ensureIndex { fieldName : "name", unique : true  }, esc defer()
    await @db.ensureIndex { fieldName : "name_to_key" }, esc defer()
    log.debug "- DB::_init_db"
    cb null

##=======================================================================

exports.db = _db = new DB {}
exports.DB = DB 
for k,v of DB.prototype
  ((key) -> exports[key] = (args...) -> _db[key](args...) )(k)

##=======================================================================
