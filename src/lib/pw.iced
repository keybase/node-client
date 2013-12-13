
read = require 'read'
log = require './log'
crypto = require 'crypto'
{Keys} = require './blockcrypt'

#=========================================================================

exports.PasswordManager = class PasswordManager

  constructor : () ->
    # This is a sensible default.  Let's not bore the users with lots of 
    # paramters they don't want to tweak.
    @pbkdf_iters = 1024

  #-------------------

  init : (opts) ->
    @opts = opts
    true

  #-------------------

  get_opts : -> @opts

  #-------------------

  _prompt_1 : (prompt, cb) ->
    await read { prompt : "#{prompt}> ", silent : true }, defer err, res
    if err
      log.error "In prompt: #{err}"
      res = null
    else if res?
      res = (res.split /\s+/).join ''
      res = null if res.length is 0
    cb res

  #-------------------

  prompt_for_old_pw : (cb) ->
    await @_prompt_1 'password', defer pw
    cb pw

  #-------------------

  prompt_for_pw : (is_new, cb) ->
    if is_new then @prompt_for_new_pw cb else @prompt_for_old_pw cb

  #-------------------

  prompt_for_new_pw : (cb) ->
    go = true
    res = null
    while go and not res
      await @_prompt_1 'passwrd', defer pw1
      if pw1?
        await @_prompt_1 'confirm', defer pw2
        if pw1 is pw2 then res = pw1
        else log.warn "Password didn't match"
      else
        go = false
    cb res

  #-------------------

  derive_key_material : (sz, is_new, cb) ->
    ret = null
    if not (salt = @opts.salt)?
      log.error "No salt given; can't derive keys"
    else
      await @get_password is_new, defer pw
      if not pw
        log.error "No password given; can't derive keys"

    if pw? and salt?
      await crypto.pbkdf2 pw, salt, @pbkdf_iters, sz, defer err, ret
      if err
        log.error "PBKDF2 failed: #{err}"

    cb ret

  #-------------------

  derive_keys : (is_new, cb) ->
    await @derive_key_material Keys.raw_length(), is_new, defer km
    cb if km? then new Keys km else null
    
  #-------------------

  get_password : (is_new, cb) ->
    if not @_pw?
      if not (pw = @opts.password)? and @opts.interactive and not @opts.bg
        await @prompt_for_pw is_new, defer pw
      @_pw = pw
    cb @_pw

#=========================================================================
