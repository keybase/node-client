
{E} = require './err'
log = require './log'
urlmod = require 'url'
{checkers} = require './checkers'

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
    if not existing or existing.merge(a)
      @_lookup[a.key] = a 

  #------------------

  found : (type_s, unspecified = true) ->

    key = switch type_s
      when 'generic_web_site' then 'web'
      else type_s

    ret = null
    if not (ret = @_lookup[key])? and unspecified
      [err, ret] = new Assert.make key
      if err?
        log.error "Error in handling unspecified assertion: #{err.message}"
      else
        ret.set_unspecified true
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
      a.generate_unspecified_warning()
    @_met = ret
    return ret

#=======================================================================

class Assert

  #---------------

  constructor : (@key, @val) ->
    @_unspecified = false

  #---------------

  @make : (key,val) ->
    err = out = null
    klass = switch key
      when 'github' then GithubAssert
      when 'twitter' then TwitterAssert 
      when 'web' then WebAssert
      when 'key' then KeyAssert
      when 'keybase' then KeybaseAssert
      when 'reddit' then RedditAssert
      when 'dns' then DnsAssert
      else 
        err = new E.BadAssertionError "unknown assertion type: #{key}"
        null

    if klass?
      out = new klass key, val
      if val? and (err = out.parse_check())? then out = null

    return [err, out]

  #---------------

  merge : (a) -> false
  found : () -> @_found = true
  parse_check : () -> null
  set_unspecified : () -> @_unspecified = true

  #---------------

  success : (u) ->
    @_uri = u
    @_success = true
    @

  #---------------

  check : () ->
    if not @_success
      log.error "Failed assertion: #{@key}:#{@val} wasn't found"
      false
    else
      true

#=======================================================================

class KeybaseAssert extends Assert

  parse_check : () ->
    if not checkers.username.f(@val) then new Error "expected a keybase username"
    else null

  set_payload : (u) -> @_username = u

  check : () ->
    ret = super()
    if not ret then #noop
    else if @_username.toLowerCase() isnt @val.toLowerCase()
      log.error "Username mismiatch: #{@_username} isn't #{@val}"
      ret = false
    else
      ret = true
    return ret

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
      ret = false
    else
      ret = true
    return ret

#=======================================================================

class DnsAssert extends Assert

  constructor : (key, val) ->
    super key, val
    @_seek = [ val ] if val?
    @_found_domains = {}

  merge : (wa2) ->
    @_seek = @_seek.concat wa2._seek
    true

  set_payload : (o) -> 
    d = o.body?.service?.domain
    @_found_domains[d] = true if d?

  parse_check : () ->
    if not(@val.match /[a-zA-Z]\.[a-zA-Z]/ ) then new Error "no domain given"
    else null

  check : () ->
    ret = true
    for s in @_seek when not @_found_domains[s]
      log.error "DNS ownership assertion failed for '#{s}'"
      ret = false
    return ret

  generate_unspecified_warning : () ->
    log.warn "Assertion for DNS zones #{JSON.stringify (k for k,v of @_found_domains)} were found but not specified"

#=======================================================================

class WebAssert extends Assert

  constructor : (key, val) ->
    super key, val
    @_seek = [ val ] if val?
    @_found_sites = {}

  merge : (wa2) ->
    @_seek = @_seek.concat wa2._seek
    true

  set_payload : (o) -> 
    u = urlmod.format(o?.body?.service).toLowerCase()
    @_found_sites[u] = true

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
    for s in @_seek when not @_found_sites[s]
      log.error "Web ownership assertion failed for '#{s}'"
      ret = false
    return ret

  generate_unspecified_warning : () ->
    log.warn "Assertion for web sites #{JSON.stringify (k for k,v of @_found_sites)} were found but not specified"

#=======================================================================

class SocialNetworkAssert extends Assert

  set_payload : (o) -> @_username = o?.body?.service?.username
  check : () ->
    ret = super()
    if not ret then #noop
    else if @_username isnt @val
      log.error "Failed assertion for '#{@key}': #{@val} expected, but found #{@_username}"
      ret = false
    else
      ret = true
    return ret

  generate_unspecified_warning : () ->
    log.warn "Assertion #{@key}:#{@_username} was found but wasn't specified"

#=======================================================================

class TwitterAssert extends SocialNetworkAssert
class GithubAssert extends SocialNetworkAssert
class RedditAssert extends SocialNetworkAssert

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
