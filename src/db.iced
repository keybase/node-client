
{env} = require './env'
sqlite3 = require 'sqlite3'
{Database} = sqlite3
fs = require 'fs'
path = require 'path'
{make_esc} = require 'iced-error'
{mkdirp} = require './fs'
{Lock} = require('iced-utils').lock
{util} = require 'pgp-utils'
log = require './log'
{constants} = require './constants'

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

  _open : (cb) ->
    esc = make_esc cb, "DB::open"
    err = null
    fn = @get_filename()
    log.debug "+ opening sqlite3 database file: #{fn}"
    await mkdirp fn, esc defer()

    db = null
    await
      db = new Database @get_filename(), sqlite3.OPEN_READWRITE|sqlite3.OPEN_CREATE, esc defer()
    @db = db

    await @_init_db esc defer()
    log.debug "- DB opened"
    cb null

  #-----

  log_key_import : ({uid,fingerprint,state}, cb) ->
    now = util.unix_time()
    q = """INSERT OR REPLACE INTO `key_import_log`
             (fingerprint,uid,mtime,state,ctime)
           VALUES($fingerprint,$uid,$now,$state,
              COALESCE (
                (SELECT ctime FROM key_import_log WHERE fingerprint = $fingerprint), 
                 $now
               ))"""
    args = 
      $uid : uid
      $fingerprint : fingerprint
      $state : state
      $now : now
    await @db.run q, args, defer err
    cb err

  #-----

  get_import_state : ({uid, fingerprint}, cb) ->
    q = "SELECT state FROM key_import_log WHERE uid=$uid AND fingerprint=$fingerprint"
    await @db.get q, { $uid: uid, $fingerprint : fingerprint }, defer err, row
    ret = if row? then row.state else constants.import_state.NONE
    cb err, ret

  #-----

  put : ({type, key, value, name}, cb) ->
    type or= key[-2...]
    esc = make_esc cb, "DB::put"

    if name?
      await @lock.acquire defer()
      await @db.run "BEGIN", esc defer()

    q = "REPLACE INTO kvstore(type,key,value) VALUES(?,?,?)"
    args = [ type, key, JSON.stringify(value) ]
    await @db.run q, args, esc defer()

    if name?
      q = "REPLACE INTO lookup(name_type,name,key_type,key) VALUES(?,?,?,?)"
      args = [ name.type, name.name, type, key ]
      await @db.run q, args, esc defer()
      await @db.run "COMMIT", esc defer()
      @lock.release()

    cb null

  #-----

  get : ({type, key}, cb) ->
    type or= key[-2...]
    q = "SELECT value FROM kvstore WHERE type=? AND key=?"
    args = [ type, key ]
    await @db.get q, args, defer err, row
    value = null
    if row?
      try
        value = JSON.parse row.value
      catch e
        err = e
    cb err, value

  #-----

  lookup : ({type, name}, cb) ->
    q = """SELECT k.type AS type, k.key AS k, k.value AS value
           FROM lookup AS l
           INNER JOIN kvstore AS k ON (l.key_type = k.type AND l.key = k.key)
           WHERE l.name_type = ?
           AND l.name = ?"""
    args = [ type, name ]
    await @db.get q, args, defer err, row
    value = null
    if row?
      try
        row.value = JSON.parse row.value
      catch e
        err = e
    cb err, row

  #-----

  _init_db : (cb) ->
    esc = make_esc cb, "DB::_init_db"
    sql_file = path.join __dirname, "..", "sql", "schema.sql"
    log.debug "+ run sql setup file: #{sql_file}"
    await fs.readFile sql_file, esc defer data
    commands = data.toString('utf8').split(/\s*;\s*/)
    for c in commands when c.match /\S+/
      await @db.run (c + ";"), esc defer()
    log.debug "- database initialized"
    cb null

##=======================================================================

exports.db = _db = new DB {}
exports.DB = DB 
for k,v of DB.prototype
  ((key) -> exports[key] = (args...) -> _db[key](args...) )(k)

##=======================================================================
