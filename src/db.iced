
{env} = require './env'
sqlite3 = require 'sqlite3'
{Database} = sqlite3
fs = require 'fs'
path = require 'path'
{make_esc} = require 'iced-error'
{mkdirp} = require './fs'

##=======================================================================

class DB

  constructor : ({@filename}) ->

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
    await mkdirp fn, esc defer()

    db = null
    await
      db = new Database @get_filename(), sqlite3.OPEN_READWRITE|sqlite3.OPEN_CREATE, esc defer()
    @db = db

    await @_init_db esc defer()
    console.log "done with init db"
    key = "aaabbcceefffeee04"
    await @put { key , value : { a: [1,2,3,3333], c : false }}, esc defer()
    await @get { key }, esc defer val
    console.log "SSS"
    console.log val
    cb null

  #-----

  put : ({type, key, value}, cb) ->
    type or= key[-2...]
    q = "REPLACE INTO kvstore(type,key,value) VALUES(?,?,?)"
    args = [ type, key, JSON.stringify(value) ]
    await @db.run q, args, defer err
    cb err

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

  _init_db : (cb) ->
    esc = make_esc cb, "DB::_init_db"
    sql_file = path.join __dirname, "..", "sql", "schema.sql"
    await fs.readFile sql_file, esc defer data
    commands = data.toString('utf8').split(/\s*;\s*/)
    for c in commands when c.match /\S+/
      await @db.run (c + ";"), esc defer()
    cb null

##=======================================================================

exports.db = _db = new DB {}
exports.DB = DB 
for k,v of DB.prototype
  ((key) -> exports[key] = (args...) -> _db[key](args...) )(k)

##=======================================================================
