
{db} = require './db'
{gpg} = require './gpg'
log = require './log'
{constants} = require './constants'
{make_esc} = require 'iced-error'
mkdirp = require 'mkdirp'
{env} = require './env'
{prng} = require 'crypto'
{athrow,base64u} = require('pgp-utils').util
{GE,E} = require './err'
path = require 'path'
fs = require 'fs'
{BufferOutStream,GPG,colgrep} = require 'gpg-wrapper'
util = require 'util'

##=======================================================================

strip = (m) -> m.split(/\s+/).join('')

states = 
  NONE : 0
  LOADED : 1
  SAVED : 2

##=======================================================================

class GpgKey 

  #-------------

  constructor : (fields) ->
    @_state = states.NONE
    for k,v of fields
      @["_#{k}"] = v

  #-------------

  # The fingerprint of the key
  fingerprint : () -> @_fingerprint

  # The 64-bit GPG key ID
  key_id_64 : () -> @_key_id_64 or @fingerprint()[-16...]

  # Something to load a key by
  load_id : () -> @key_id_64() or @fingerprint()

  # The keybase username of the keyholder
  username : () -> @_username

  # The keybase UID of the keyholder
  uid : () -> @_uid

  # Return the raw armored PGP key data
  key_data : () -> @_key_data

  # The keyring object that we've wrapped in
  keyring : () -> @_keyring

  # These two functions are to fulfill to key manager interface
  get_pgp_key_id : () -> @key_id_64()
  get_pgp_fingerprint : () -> @fingerprint().toLowerCase()

  is_signed : () -> !!@_is_signed

  #-------------

  check_is_signed : (signer, cb) ->
    log.debug "+ Check if #{signer.to_string()} signed #{@to_string()}"
    id = @load_id()
    args = [ "--list-sigs", "--with-colons", id ]
    await @gpg { args }, defer err, out
    unless err?
      rows = colgrep { buffer : out, patterns : { 0 : /^sig$/ }, separator : /:/  }
      to_find = signer.key_id_64().toUpperCase()
      for row in rows
        if row[4] is to_find
          log.debug "| Found in row: #{JSON.stringify row}"
          @_is_signed = true
          break
    log.debug "- Check -> #{@_is_signed}"
    cb err, @_is_signed

  #-------------

  # Find the key in the keyring based on fingerprint
  find : (cb) ->
    if (fp = @fingerprint())?
      args = [ "-" + (if @_secret then 'K' else 'k'), "--with-colons", fp ]
      await @gpg { args, quiet : true }, defer err, out
      if err?
        err = new E.NoLocalKeyError (
          if @_is_self then "You don't have a local key!"
          else "the user #{@_username} doesn't have a local key"
        )
    else
      err = new E.NoRemoteKeyError (
        if @_is_self then "You don't have a registered remote key! Try `keybase push`"
        else "the user #{@_username} doesn't have a remote key"
      )
    cb err

  #-------------

  # Check that this key has been signed by the signing key.
  check_sig : (signing_key, cb) ->
    args = [ '--list-sigs', '--with-colon', @fingerprint() ]
    await @gpg { args }, defer err, out
    unless err?
      rows = colgrep { buffer : out, patterns : {
          0 : /^sub$/
          4 : (new RegExp "^#{signing_key.key_id_64()}$", "i")
        }
      }
      if rows.length is 0
        err = new E.VerifyError "No signature of #{@to_string()} by #{signing_key.to_string()}"
    cb err

  #-------------

  to_string : () -> [ @username(), @key_id_64() ].join "/"

  #-------------

  gpg : (gargs, cb) -> @keyring().gpg gargs, cb

  #-------------

  # Save this key to the underlying GPG keyring
  save : (cb) ->
    args = [ "--import" ]
    log.debug "| Save key #{@to_string()} to #{@keyring().to_string()}"
    await @gpg { args, stdin : @_key_data, quiet : true }, defer err
    @_state = states.SAVED
    cb err

  #-------------

  # Load this key from the underlying GPG keyring
  load : (cb) ->
    id = @load_id()
    esc = make_esc cb, "GpgKey::load"
    args = [ 
      (if @_secret then "--export-secret-key" else "--export" ),
      "--export-options", "export-local-sigs", 
      "-a",
      id
    ]
    log.debug "| Load key #{@to_string()} from #{@keyring().to_string()} (secret=#{@_secret})"
    await @gpg { args }, esc defer @_key_data
    if not @fingerprint()?
      log.debug "+ lookup fingerprint"
      args = [ "-k", "--fingerprint", "--with-colons", id ]
      await @gpg { args }, esc defer out
      rows = colgrep { buffer : out, patterns : { 0 : /^fpr$/ } }
      if (rows.length is 0) or not (@_fingerprint = rows[0][9])?
        err = new GE.GpgError "Couldn't find GPG fingerprint for #{id}"
      else
        @_state = states.LOADED
        log.debug "- Map #{id} -> #{@_fingerprint} via gpg"
    cb err

  #-------------

  # Remove this key from the keyring
  remove : (cb) ->
    args = [
      (if @_secret then "--delete-secret-and-public-key" else "--delete-keys"),
      "--batch",
      "--yes",
      @fingerprint()
    ]
    log.debug "| Delete key #{@to_string()} from #{@keyring().to_string()}"
    await @gpg { args }, defer err
    cb err

  #-------------

  # Read the userIds that have been signed with this key
  read_uids_from_key : (cb) ->
    args = { fingerprint : @fingerprint() }
    await @keyring().read_uids_from_key args, defer err, uids
    cb err, uids

  #-------------

  sign_key : (signer, cb) ->
    log.debug "| GPG-signing #{@username()}'s key with your key"
    args = [ "-u", signer.fingerprint(), "--sign-key", "--batch", "--yes", @fingerprint() ]
    await @gpg { args, quiet : true }, defer err
    cb err

  #-------------

  # Assuming this is a temporary key, commit it to the master key chain, after signing it
  commit : (signer, cb) ->
    esc = make_esc cb, "GpgKey::commit"
    if @keyring().is_temporary()
      log.debug "+ #{@to_string()}: Commit temporary key"
      await @sign_key signer, esc defer()
      await @load esc defer()
      await @remove esc defer()
      await (@copy_to_keyring master_ring()).save esc defer()
      log.debug "- #{@to_string()}: Commit temporary key"
    else if not @_is_signed
      log.debug "| #{@to_string()}: signing key, since it wasn't signed"
      await @sign_key signer, esc defer()
    else
      log.debug "| #{@to_string()}: key was previously commited; noop"
    cb null

  #-------------

  rollback : (cb) ->
    s = @to_string()
    err = null
    if env().get_preserve_tmp_keyring() and @keyring().is_temporary()
      log.debug "| #{s}: preserving temporary keyring by command-line flag"
    else if @keyring().is_temporary()
      log.debug "| #{s}: Rolling back temporary key"
      await @remove defer err
    else
      log.debug "| #{s}: no need to rollback key, it's permanent"
    cb err

  #-------------

  # Make a key object from a User object
  @make_from_user : ({user, secret, keyring}) ->
    new GpgKey {
      user : user ,
      secret : secret,
      username : user.username(),
      is_self : user.is_self(),
      uid : user.id,
      key_data : user?.public_keys?.primary?.bundle,
      keyring : keyring,
      fingerprint : user.fingerprint(true)
    }

  #-------------

  copy_to_keyring : (keyring) ->
    d = {}
    d[k[1...]] = v for k,v of @ when k[0] is '_'
    ret = new GpgKey d
    ret._keyring = keyring
    return ret

  #--------------

  _find_key_in_stderr : (which, buf) ->
    err = ki64 = fingerprint = null
    d = buf.toString('utf8')
    if (m = d.match(/Primary key fingerprint: (.*)/))? then fingerprint = m[1]
    else if (m = d.match(/using [RD]SA key ([A-F0-9]{16})/))? then ki64 = m[1]
    else err = new E.VerifyError "#{which}: can't parse PGP output in verify signature"
    return { err, ki64, fingerprint } 

  #--------------

  _verify_key_id_64 : ( {ki64, which, sig}, cb) ->
    log.debug "+ GpgKey::_verify_key_id_64: #{which}: #{ki64} vs #{@fingerprint()}"
    err = null
    if ki64 isnt @key_id_64() 
      await @gpg { args : [ "--fingerprint", "--keyid-format", "long", ki64 ] }, defer err, out
      if err? then # noop
      else if not (m = out.toString('utf8').match(/Key fingerprint = ([A-F0-9 ]+)/) )?
        err = new E.VerifyError "Querying for a fingerprint failed"
      else if not (a = strip(m[1])) is (b = @fingerprint())
        err = new E.VerifyError "Fingerprint mismatch: #{a} != #{b}"
      else
        log.debug "| Successful map of #{ki64} -> #{@fingerprint()}"

    unless err?
      await @keyring().assert_no_collision ki64, defer err

    log.debug "- GpgKey::_verify_key_id_64: #{which}: #{ki64} vs #{@fingerprint()} -> #{err}"
    cb err

  #-------------

  verify_sig : ({which, sig, payload}, cb) ->
    log.debug "+ GpgKey::verify_sig #{which}"
    esc = make_esc cb, "GpgKEy::verify_sig"
    err = null

    stderr = new BufferOutStream()
    await @gpg { args : [ "--decrypt", "--keyid-format", "long"], stdin : sig, stderr }, defer err, out

    # Check that the signature verified, and that the intended data came out the other end
    msg = if err? then "signature verification failed"
    else if ((a = out.toString('utf8')) isnt (b = payload)) then "wrong payload: #{a} != #{b}"
    else null

    # If there's an exception, we can now throw out of this function
    if msg? then await athrow (new E.VerifyError "#{which}: #{msg}"), esc defer()

    # Now we need to check that there's a short Key id 64, or a full fingerprint
    # in the stderr output of the verify command
    {err, ki64, fingerprint} = @_find_key_in_stderr which, stderr.data()

    if err then #noop
    else if ki64? 
      await @_verify_key_id_64 { which, ki64, sig }, esc defer()
    else if (a = strip(fingerprint)) isnt (b = @fingerprint())
      err = new E.VerifyError "#{which}: mismatched fingerprint: #{a} != #{b}"

    log.debug "- GpgKey::verify_sig #{which} -> #{err}"
    cb err

  #-------


##=======================================================================

exports.BaseKeyRing = class BaseKeyRing extends GPG

  constructor : () ->

  #------

  make_key : (opts) ->
    opts.keyring = @
    return new GpgKey opts

  #------

  make_key_from_user : (user, secret) ->
    return GpgKey.make_from_user { user, secret, keyring : @ }

  #------

  is_temporary : () -> false

  #------

  gpg : (gargs, cb) ->
    log.debug "| Call to gpg: #{util.inspect gargs}"
    gargs.quiet = false if gargs.quiet and env().get_debug()
    await @run gargs, defer err, res
    cb err, res

##=======================================================================

exports.MasterKeyRing = class MasterKeyRing extends BaseKeyRing

  to_string : () -> "master keyring"

##=======================================================================

_mring = new MasterKeyRing()
exports.master_ring = master_ring = () -> _mring

##=======================================================================

exports.load_key = (opts, cb) ->
  delete opts.signer if (signer = opts.signer)?
  key = master_ring().make_key opts
  await key.load defer err
  if not err? and signer?
    await key.check_is_signed signer, defer err
  cb err, key

##=======================================================================

class TmpKeyRingBase extends BaseKeyRing

  constructor : (@dir) ->

  #------

  to_string : () -> "tmp keyring #{@dir}"

  #------

  mkfile : (n) -> path.join @dir, n

  #------

  post_make : (cb) -> cb null

  #------

  @make : (klass, cb) ->
    mode = 0o700
    log.debug "+ Make new temporary keychain"
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

    log.debug "- Made new temporary keychain"
    tkr = if err? then null else (new klass dir)
    if tkr? and not err?
      await tkr.post_make defer err
    cb err, tkr

  #----------------------------

  copy_key : (k1, cb) ->
    esc = make_esc cb, "TmpKeyRing::copy_key"
    await k1.load esc defer()
    k2 = k1.copy_to_keyring @
    await k2.save esc defer()
    cb()

  #----------------------------

  is_temporary : () -> true

  #----------------------------

  list_keys : (cb) ->
    await @gpg { args : [ "-k", "--with-colons" ], list_keys : true }, defer err, out
    unless err?
      rows = colgrep { buffer : out, patterns : { 0 : /^pub$/ }, separator : /:/ }
      @_all_id_64s = (row[4] for row in rows)
    cb err, @_all_id_64s

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

exports.TmpKeyRing = class TmpKeyRing extends TmpKeyRingBase

  #------

  @make : (cb) -> TmpKeyRingBase.make TmpKeyRing, cb

  #------

  # The GPG class will call this right before it makes a call to the shell/gpg.
  # Now is our chance to talk about our special keyring
  mutate_args : (gargs) ->
    gargs.args = [
      "--no-default-keyring",
      "--keyring",            @mkfile("pub.ring"),
      "--secret-keyring",     @mkfile("sec.ring"),
      "--trustdb-name",       @mkfile("trust.db")
    ].concat gargs.args
    log.debug "| Mutate GPG args; new args: #{gargs.args.join(' ')}"

##=======================================================================

exports.TmpPrimaryKeyRing = class TmpPrimaryKeyRing extends TmpKeyRingBase

  #------

  @make : (cb) -> TmpKeyRingBase.make TmpPrimaryKeyRing, cb

  #------

  # The GPG class will call this right before it makes a call to the shell/gpg.
  # Now is our chance to talk about our special keyring
  mutate_args : (gargs) ->
    prepend = [ "--primary-keyring", @mkfile("pub.ring") ]
    if gargs.list_keys then prepend.push "--no-default-keyring"
    gargs.args = prepend.concat gargs.args
    log.debug "| Mutate GPG args; new args: #{gargs.args.join(' ')}"

  #------

  post_make : (cb) -> 
    await fs.writeFile @mkfile("pub.ring"), (new Buffer []), defer err
    cb err

##=======================================================================


