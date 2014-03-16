
{E} = require './err'
log = require './log'

#=======================================================================

class Assertions 

  constructor : () -> 
    @_list = []
    @_lookup = {}
    @_unspecified = []

  push : (a) -> 
    @_list.push a
    @_lookup[a.key] = a 

  found : (type_s) ->
    if not (ret = @_lookup[type_s])?
      ret = new UnspecifiedAssert type_s
      @_unspecified.push ret
    ret.found()
    ret

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

class SocialNetworkAssert
  constructor : (@key, @val) ->

  @make : (key,val) ->
    err = out = null
    out = switch key
      when 'github' then new GithubAssert key, val
      when 'twitter' then new TwitterAssert key, val
      else 
        err = new E.BadAssertionError "unknown assertion type: #{key}"
        null
    return [err, out]

  set_proof_service_object : (o) -> @_username = o.username
  found : () -> @_found = true

  success : (u) ->
    @_uri = u
    @_success = true

  check : () ->
    ret = false
    if not @_success
      log.error "Failed assertion: #{@key}:#{@val} wasn't found"
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
