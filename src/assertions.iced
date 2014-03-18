
{E} = require './err'
log = require './log'
urlmod = require 'url'

#=======================================================================

class Assertions 

  constructor : () -> 
    @_list = []
    @_lookup = {}
    @_unspecified = []

  #------------------

  push : (a) -> 
    @_list.push a
    existing = @_lookup[a.key]
    if not existing or existing.mege(a)
      @_lookup[a.key] = a 

  #------------------

  found : (type_s, unspecified = true) ->

    key = switch type_s
      when 'generic_web_service' then 'web'
      else type_s

    ret = null
    if not (ret = @_lookup[key])? and unspecified
      ret = new UnspecifiedAssert key
      @_unspecified.push ret

    ret?.found()
    ret

  #------------

  met : () -> @_met
  clean : () -> @_met and not @_unspecified.length

  check : () ->
    ret = true
    for a in @_list
      ret = false unless a.check()
    for a in @_unspecified
      a.generate_warning()
    @_met = ret
    return ret

#=======================================================================

class Assert

  #---------------

  constructor : (@key, @val) ->

  #---------------

  @make : (key,val) ->
    err = out = null
    klass = switch key
      when 'github' then GithubAssert
      when 'twitter' then TwitterAssert 
      when 'web' then WebAssert
      when 'key' then KeyAssert
      else 
        err = new E.BadAssertionError "unknown assertion type: #{key}"
        null

    if klass?
      out = new klass key, val
      if (err = out.parse_check())? then out = null

    return [err, out]

  #---------------

  merge : (a) -> false
  found : () -> @_found = true
  parse_check : () -> null

  #---------------

  success : (u) ->
    @_uri = u
    @_success = true
    @

  #---------------

  check : () ->
    if not @_success
      log.error "Failed assertion : #{@key}:#{@val} wasn't found"
      false
    else
      true

#=======================================================================

keycmp = (k1, k2) ->
  rev = (x) -> (c for c in x by -1).join('')
  if k2.length > k1.length then return false
  k1 = rev k1.toLowerCase()
  k2 = rev k2.toLowerCase()
  return (k1.indexOf(k2) is 0)

class KeyAssert extends Assert

  parse_check : () ->
    if not(@val.match /^[a-fA-F0-9]+$/) then new Error "expected a hexidecimal key fingerprint"
    else if not(@val.length in [ 8, 16, 40]) then new Error "expected a short, long or full fingerprint"
    else null

  set_payload : (f) -> @_fingerprint = f

  check : () ->
    ret = super()
    if not ret then #noop
    else if not keycmp(@_fingerprint, @val)
      log.error "Key mismatch: #{@val} doesn't match #{@_fingerprint}"
    else
      ret = true
    return ret

#=======================================================================

class WebAssert extends Assert

  constructor : (key, val) ->
    super key, val
    @_seek = [ val ] 
    @_found = {}

  merge : (wa2) ->
    @_seek = @_seek.concat wa2._seek

  set_payload : (o) -> 
    u = urlmod.format(o?.body?.service).toLowerCase()
    @_found[u] = true

  parse_check : () ->
    u = urlmod.parse @val
    if not(u.hostname.match /[a-zA-Z]\.[a-zA-Z]/ ) then new Error "no hostname given"
    else if (u.pathname? and (u.pathname isnt '/')) then new Error "can't specify a path"
    else if u.port? then new Error "can't specify a port"
    else
      u.protocol = "https:" unless u.protocol?
      @val = u.format()
      null

  check : () ->
    ret = true
    for s in @_seek when not @_found[s]
        log.error "Web ownership assertion failed for '#{s}'"
        ret = false
    return ret

#=======================================================================

class SocialNetworkAssert extends Assert

  set_payload : (o) -> @_username = o?.body?.service?.username
  check : () ->
    ret = super()
    if not ret then #noop
    else if @_username isnt @val
      log.error "Failed assertion for '#{@key}': #{@val} expected, but found #{@_username}"
    else
      ret = true
    return ret

#=======================================================================

class TwitterAssert extends SocialNetworkAssert
class GithubAssert extends SocialNetworkAssert

#=======================================================================

class UnspecifiedAssert extends Assert

  generate_warning : () ->
    if @_success
      log.warn "Unspecified assertion: #{@key}:#{@_username} is also true"

#=======================================================================

exports.parse = (v) ->
  out = new Assertions()
  for ass in v
    if (m = ass.match /^([^\s:]+):(.*)$/) 
      [err, assert] = Assert.make m[1], m[2]
    else
      err = new E.BadAssertionError "Bad assertion, couldn't parse: #{ass}"
    break if err?
    out.push assert
  out = null if err?
  return [err, out]

#=======================================================================
