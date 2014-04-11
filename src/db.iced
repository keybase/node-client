
{env} = require './env'
fs = require 'fs'
path = require 'path'
{chain,make_esc} = require 'iced-error'
{mkdirp} = require './fs'
iutils = require 'iced-utils'
{Lock} = iutils.lock
{Lockfile} = iutils.lockfile
{util} = require 'pgp-utils'
log = require './log'
{constants} = require './constants'
Datastore = require 'nedb'
lockfile = require 'lockfile'

##=======================================================================

make_key = ({ table, type, id }) -> [ table, type, id].join(":").toLowerCase()
make_kvstore_key = ( {type, key } ) -> 
  type or= key[-2...]
  make_key { table : "kv", type, id : key }
make_lookup_key = ( {type, name} ) -> make_key { table : "lo", type, id : name }

##=======================================================================

class DB

  constructor : ({@filename}) ->
    @lock = new Lock
    @lockfile = null

  #----

  get_filename : () ->
    @filename or= env().get_db_filename()
    return @filename

  #----

  get_lockfile_name : () ->
    @get_filename() + ".lock"

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

  _get_lockfile : (cb) ->
    @lockfile or= new Lockfile { filename : @get_lockfile_name() }
    nm = @lockfile.filename
    log.debug "+ acquire lockfile #{nm}"
    await @lockfile.acquire defer err
    if err?
      log.warn "Could not acquire lockfile #{nm}"
    log.debug "- acquire lockfile #{nm} -> #{err}"
    cb err

  #----

  compact : (cb) ->
    esc = make_esc cb, "DB::compact"
    err = null
    log.debug "+ compact"
    await @_get_lockfile esc defer()
    await @db.persistence.persistCachedDatabase defer err
    await @lockfile.release esc defer()
    log.debug "- compact"
    cb err

  #----

  close : (cb) ->
    err = null
    if @db 
      await @lock.acquire defer()
      await @compact defer err
      @lock.release()
    cb err

  #----

  _open : (cb) ->
    esc = make_esc cb, "DB::open"
    err = null
    fn = @get_filename()
    log.debug "+ opening NEDB database file: #{fn}"
    await mkdirp fn, esc defer()
    @db = new Datastore { filename : @get_filename() }
    @db.persistence.stopAutocompaction()
    await @db.loadDatabase esc defer()
    await @_init_db esc defer()
    log.debug "- DB opened"
    cb null

  #-----

  put : ({type, key, value, name, names}, cb) ->
    k = make_kvstore_key {type,key}
    docs = [ { key : k, value : value } ]

    names  = [ name ] if name? and not names?
    if names and names.length
      for name in names
        docs.push { key : make_lookup_key(name), name_to_key : k }

    err = null
    for doc in docs
      await @db.update { key : doc.key }, doc, { upsert : true }, defer tmp
      if tmp? and not err? then err = tmp

    cb err

  #-----

  remove : ({type, key}, cb) ->
    k = make_kvstore_key { type, key }
    log.debug "+ DB remove #{k}"
    esc = make_esc cb, "DB::remove"
    await @db.remove { key : k }, { mutli : true }, esc defer()
    await @db.remove { name_to_key : k }, { multi : true }, esc defer()
    log.debug "- DB remove #{k} -> ok"
    cb null

  #-----

  find1 : (q, cb) ->
    await @db.find q, defer err, docs
    err = value = null
    if err? then # noop
    else if (l = docs.length) is 0 then value = null
    else if l > 1 then err = new E.CorruptionError "Got #{s} docs back; only wanted 1"
    else value = docs[0]
    cb err, value

  #-----

  get : ({type, key}, cb) ->
    k = make_kvstore_key { type, key }
    await @find1 { key : k }, defer err, value
    value = value?.value
    cb err, value

  #-----

  lookup : ({type, name}, cb) ->
    k = make_lookup_key { type, name }
    err = value = null
    await @find1 { key : k }, defer err, value
    if not err? and (k = value?.name_to_key)?
      await @find1 { key : k }, defer err, value
    cb err, value

  #-----

  _init_db : (cb) ->
    log.debug "+ DB::_init_db"
    esc = make_esc cb, "DB::_init_db"
    await @db.ensureIndex { fieldName : "key" , unique : true }, esc defer()
    log.debug "- DB::_init_db"
    cb null

##=======================================================================

exports.db = _db = new DB {}
exports.DB = DB 
for k,v of DB.prototype
  ((key) -> exports[key] = (args...) -> _db[key](args...) )(k)

##=======================================================================
