
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

  read_field : (k,{prompt,passphrase,checker,confirm,defval,thrower,first_prompt,hint,normalizer,stderr}, cb) ->
    err = null
    ok = false
    first = true

    until ok
      p = if first then (prompt + (if first_prompt? then first_prompt else "") + ": ")
      else (prompt + " (" + (hint or checker.hint) + "): ")
      first = false

      obj = { prompt : p }
      obj.output = process.stderr if stderr?
      if passphrase
        obj.silent = true
        obj.replace = "*"
      if (d = @_data[k])? or (d = defval)?
        obj.default = d
        obj.edit = true
      await read obj, defer err, res, isDefault
      break if err?

      # Normalize the output first, maybe by stripping off leading '@'
      # signs
      if normalizer? then res = normalizer(res)

      if thrower? and (err = thrower(k, res))? then ok = true
      else if checker?.f? and not checker.f res then ok = false
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
  win = (process.platform is 'win32')
  if win then defval = null
  ch = if defval? then "[#{if defval then 'Y' else 'y'}/#{if not(defval) then 'N' else 'n' }]" else '[y/n]'
  prompt += " #{ch} "
  obj = { prompt }
  ret = null
  err = null
  while not ret? and not err?
    await read obj, defer err, res
    if not err?
      res = strip res
      if (res.length is 0) 
        if defval? then ret = defval
      else if "yes".indexOf(res.toLowerCase()) >= 0 
        ret = true
      else if "no".indexOf(res.toLowerCase()) >= 0
        ret = false
  cb err, ret

#========================================================================

exports.prompt_passphrase = ({prompt,confirm,extra,short,no_leading_space,stderr}, cb) ->
  unless prompt?
    prompt = "Your keybase login passphrase"
    prompt += extra if extra?

  checker = if short then checkers.passphrase_short
  else if no_leading_space then checkers.passphrase_nls 
  else checkers.passphrase

  seq = 
    passphrase :
      prompt : prompt
      passphrase : true
      checker : checker
      confirm : confirm
      stderr : stderr
  p = new Prompter seq
  await p.run defer err
  cb err, p.data().passphrase

#========================================================================

exports.prompt_remote_name = ({prompt, checker, hint}, cb) ->
  seq = { name : { prompt, checker, hint } }
  p = new Prompter seq
  await p.run defer err
  cb err, p.data().name

#========================================================================

exports.prompt_email_or_username = (cb) ->
  seq = 
    email_or_username :
      prompt : "Your keybase username or email"
      checker : checkers.email_or_username
  p = new Prompter seq
  await p.run defer err
  if err? then out = {}
  else
    v = p.data().email_or_username
    out =
      email : (if checkers.email.f(v) then v else null)
      username : (if checkers.username.f(v) then v else null)
  cb err, out

#========================================================================

exports.prompt_for_int = ({prompt, low, hi, defint, hint, first_prompt}, cb) ->
  seq =
    key :
      prompt : prompt
      checker : checkers.intcheck(low, hi, defint)
      hint : hint
      first_prompt : first_prompt
  p = new Prompter seq
  await p.run defer err

  out = if err? then null
  else if (d = p.data().key) is '' and defint? then defint
  else parseInt(d)

  cb err, out

#========================================================================
