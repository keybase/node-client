
read = require 'read'
log = require './log'
crypto = require 'crypto'

#=========================================================================

exports.PasswordManager = class PasswordManager

  constructor : () ->

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

  get_password : (is_new, cb) ->
    if not @_pw?
      if not (pw = @opts.password)? and @opts.interactive and not @opts.bg
        await @prompt_for_pw is_new, defer pw
      @_pw = pw
    cb @_pw

#=========================================================================
