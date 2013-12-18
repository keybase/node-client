
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

    cb null

  #-----

  _init_db : (cb) ->
    esc = make_esc cb, "DB::_init_db"
    sql_file = path.join __dirname, "..", "sql", "schema.sql"
    await fs.readFile sql_file, esc defer data
    commands = data.toString('utf8').split(/\s*;\s*/)
    for c in commands when c.match /\S+/
      await @db.run (c + ";"), esc defer()
      console.log "OK for #{c}"
    console.log "ok, ready to rock out of here..."
    cb null

##=======================================================================

exports.db = _db = new DB {}
exports.DB = DB 
for k,v of DB.prototype
  ((key) -> exports[key] = (args...) -> _db[key](args...) )(k)

##=======================================================================
