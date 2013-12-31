
read = require 'read'
{checkers} = require './checkers'
log = require './log'

#========================================================================

exports.Prompter = class Prompter 

  constructor : (@_fields) -> @_data = {}
  data        : ()         -> @_data
  clear       : (k)        -> delete @_data[k]

  #-------------------

  run : (cb) ->
    err = null
    for k,v of @_fields
      await @read_field k, v, defer err
      break if err?
    cb err

  #-------------------

  read_field : (k,{prompt,passphrase,checker,confirm,defval}, cb) ->
    err = null
    ok = false
    first = true

    until ok
      p = if first then (prompt + ": ")
      else (prompt + " (" + checker.hint + "): ")
      first = false

      obj = { prompt : p } 
      if passphrase
        obj.silent = true
        obj.replace = "*"
      if (d = @_data[k])? or (d = defval)?
        obj.default = d
        obj.edit = true
      await read obj, defer err, res, isDefault
      break if err?

      if checker?.f? and not checker.f res then ok = false
      else if not confirm? or isDefault then ok = true
      else
        delete obj.default
        obj.edit = false
        obj.prompt = confirm.prompt + ": "
        await read obj, defer err, res2
        if res2 isnt res
          ok = false
          log.warn "Passphrases didn't match! Try again."
        else
          ok = true
      if ok
        @_data[k] = res if not(isDefault) or not(@_data[k]?)

    cb err

#========================================================================

strip = (s) ->
  x = /^\s*(.*?)\s*$/
  if (m = s.match x)? then s = m[1]
  return s

#--------

exports.prompt_yn = ({prompt,defval}, cb) ->
  ch = "[#{if defval then 'Y' else 'y'}/#{if not(defval) then 'N' else 'n' }]"
  prompt += " #{ch} "
  obj = { prompt }
  ret = null
  err = null
  while not ret? and not err?
    await read obj, defer err, res
    if not err?
      res = strip res
      if res.length is 0
        ret = defval
      else if "yes".indexOf(res.toLowerCase()) >= 0 
        ret = true
      else if "no".indexOf(res.toLowerCase()) >= 0
        ret = false
  cb err, ret

#========================================================================

exports.prompt_passphrase = (cb) ->
  seq = 
    passphrase :
      prompt : "Your login passphrase"
      passphrase : true
      checker : checkers.passphrase
  p = new Prompter seq
  await p.run defer err
  cb err, p.data().passphrase

#========================================================================

exports.prompt_remote_username = (svc, cb) ->
  seq = 
    username :
      prompt : "Your username on #{svc}"
      checker : checkers.username
  p = new Prompter seq
  await p.run defer err
  cb err, p.data().username


#========================================================================

exports.prompt_email_or_username = (cb) ->
  seq = 
    email_or_username :
      prompt : "Your username or email"
      checker : checkers.email_or_username
  p = new Prompter seq
  await p.run defer err
  if err? then out = null
  else
    v = p.data().email_or_username
    out =
      email : (if checkers.email.f(v) then v else null)
      username : (if checkers.username.f(v) then v else null)
  cb err, out

#========================================================================

exports.prompt_for_int = (low, hi, cb) ->
  seq =
    key :
      prompt : "Pick a key"
      checker : checkers.intcheck(low, hi)
  p = new Prompter seq
  await p.run defer err
  out = if err? then null else parseInt(p.data().key)
  cb err, out

#========================================================================
