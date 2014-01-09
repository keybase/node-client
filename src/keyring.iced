
{db} = require './db'
{gpg} = require './gpg'
log = require './log'
{constants} = require './constants'
{make_esc} = require 'iced-error'
mkdirp = require 'mkdirp'
{env} = require './env'
{prng} = require 'crypto'
{base64u} = require('pgp-utils').util
path = require 'path'
fs = require 'fs'

##=======================================================================

exports.clean_key_imports = (cb) ->
  esc = make_esc cb, "clean_key_imports"
  log.debug "+ clean key imports"
  state = constants.import_state.TEMPORARY
  await db.select_key_imports_by_state state, esc defer keys
  log.debug "| queried for temp keys, got: #{JSON.stringify keys}"
  if keys.length
    args = [ "--batch", "--delete-keys" ].concat(k.toUpperCase() for k in keys)
    log.debug "| calling GPG client with #{JSON.stringify args}"  
    await gpg { args, tmp : true }, defer err
    state = constants.import_state.CANCELED
    await db.batch_update_key_import { fingerprints : keys, state }, esc defer()
  log.debug "- clean key imports"
  cb null

##=======================================================================

exports.TempKeyRing = class TempKeyRing

  constructor : (@dir) ->

  @make : (cb) ->
    mode = 0o700
    parent = env().get_tmp_keyring_dir()
    await mkdirp parent, mode, defer err, made
    if err?
      log.error "Error making tmp keyring dir #{parent}: #{err.message}"
    else if made
      log.info "Creating tmp keyring dir: #{parent}"
    else
      await fs.stat parent, defer err, so
      if err?
        log.error "Failed to stat directory #{parent}: #{err.message}"
      else if (so.mode & 0o777) isnt mode
        await fs.chmod dir, mode, defer err
        if err?
          log.error "Failed to change mode of #{parent} to #{mode}: #{err.message}"

    unless err?
      nxt = base64u.encode prng 12
      dir = path.join parent, nxt
      await fs.mkdir dir, mode, defer err
      log.debug "| making directory #{dir}"
      if err?
        log.error "Failed to make dir #{dir}: #{err.message}"

    tkr = if err? then null else (new TempKeyRing dir)
    cb err, tkr

  #----------------------------

  nuke : (cb) ->
    await fs.readdir @dir, defer err, files
    if err?
      log.error "Cannot read dir #{@dir}: #{err.message}"
    else 
      for file in files
        fp = path.join(@dir, file)
        await fs.unlink fp, defer e2
        if e2?
          log.warn "Could not remove dir #{fp}: #{e2.message}"
          err = e2
      unless err?
        await fs.rmdir @dir, defer err
        if err?
          log.error "Cannot delete tmp keyring @dir: #{err.message}"
    cb err

##=======================================================================

