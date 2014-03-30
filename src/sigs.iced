proofs = require 'keybase-proofs'
{make_esc} = require 'iced-error'
req = require './req'
{constants} = require './constants'
session = require './session'
{env} = require './env'
log = require './log'
{master_ring} = require './keyring'
{decode} = require('pgp-utils').armor
colors = require './colors'
{E} = require './err'
req = require './req'
urlmod = require 'url'

#===========================================

class BaseSigGen

  constructor : ({@km}) ->

  #---------

  _get_seqno_type : () -> "PUBLIC"

  #---------

  _get_announce_number : (cb) ->
    type = @_get_seqno_type()
    await req.get { endpoint : "sig/next_seqno", args : { type } }, defer err, body
    unless err?
      @seqno = body.seqno
      @prev = body.prev
    cb err

  #---------

  _get_binding_eng : () ->
    @_make_binding_eng {
      sig_eng : (new SignatureEngine {@km} ),
      @seqno,
      @prev,
      host : constants.canonical_host,
      user : 
        local :
          uid : session.get_uid()
          username : env().get_username()
    }

  #---------

  _do_signature : (cb) -> 
    eng = @_get_binding_eng()
    await eng.generate defer err, @sig
    cb err

  #---------

  _v_modify_store_arg : (arg) ->
  _get_api_endpoint : () -> "sig/post"

  #---------

  _store_signature : (cb) ->
    args = 
      sig : @sig.pgp
      sig_id_base : @sig.id
      sig_id_short : @sig.short_id
      is_remote_proof : true
    @_v_modify_store_arg args
    endpoint = @_get_api_endpoint()
    log.debug "+ storing signature:"
    log.debug "| writing to #{endpoint}"
    log.debug "| with args #{JSON.stringify args}"
    await req.post { endpoint, args }, defer err, body
    unless err?
      { @proof_text, @proof_id, @sig_id } = body
      log.debug "| reply with value: #{JSON.stringify body}"
    log.debug "- stored signature (err = #{err?.message})"
    cb err

  #---------

  run : (cb) ->
    esc = make_esc cb, "BaseSigGen::run"
    await @_get_announce_number esc defer()
    await @_do_signature esc defer()
    await @_store_signature esc defer()
    cb null, @sig

  #-----------------------

  normalize_name : (n, cb) -> 
    klass = @_binding_klass()
    ret = klass.normalize_name(n)
    cb null, ret

  #-----------------------

  check_name : (s) -> @_binding_klass().check_name(s)

  #-----------------------

  # Check the input that came in from the user, often the same as the
  # name that's eventually used in the proof, though it could change...
  check_name_input : (s) -> @check_name(s)

  #-----------------------
  
  single_occupancy : () -> @_binding_klass().single_occupancy()

  #-----------------------

  get_warnings : ({}) -> []
  
#===========================================

exports.KeybaseProofGen = class KeybaseProofGen extends BaseSigGen 

  _v_modify_store_arg : (arg) ->
    arg.type = "web_service_binding.keybase"
    arg.is_remote_proof = false

  _make_binding_eng : (arg) -> new proofs.KeybaseBinding arg

#===========================================

exports.KeybasePushProofGen = class KeybasePushProofGen extends BaseSigGen 

  # stub this out since it's not needed; we'll be doing a post elsewhere
  _store_signature : (cb) -> cb null
  
  _make_binding_eng : (arg) -> 
    new proofs.KeybaseBinding arg

#===========================================

exports.TrackerProofGen = class TrackerProofGen extends BaseSigGen

  constructor : ({km,@prev,@seqno,@uid,@track}) ->
    super { km }

  _get_announce_number : (cb) -> cb null

  _make_binding_eng : (arg) -> 
    arg.track = @track
    new proofs.Track arg

  _v_modify_store_arg : (arg) -> 
    arg.uid = @uid
    arg.type = "track"
  _get_api_endpoint : () -> "follow"

#===========================================

exports.UntrackerProofGen = class UntrackerProofGen extends BaseSigGen

  constructor : ({km,@uid,@untrack,@seqno,@prev}) ->
    super { km }

  _get_announce_number : (cb) -> cb null

  _make_binding_eng : (arg) -> 
    arg.untrack = @untrack
    new proofs.Untrack arg

  _v_modify_store_arg : (arg) -> 
    arg.uid = @uid
    arg.type = "untrack"
  _get_api_endpoint : () -> "follow"

#===========================================

strip_at = (x) ->
  if x? and x.length and x[0] is '@' then x[1...]
  else x

#===========================================

class SocialNetworkProofGen extends BaseSigGen
  constructor : (args) ->
    @remote_username = args.remote_name_normalized
    super args

  _make_binding_eng : (args) ->
    args.user.remote = @remote_username
    klass = @_binding_klass()
    new klass args

  _v_modify_store_arg : (arg) ->
    arg.remote_username = @remote_username
    arg.type = "web_service_binding." + @_remote_service_name()

  prompter : () -> 
    klass = @_binding_klass()
    ret = {
      prompt  : "Your username on #{@display_name()}"
      checker : 
        f         : klass.check_name
        hint      : klass.name_hint()
        normalize : klass.normalize_name
    }
    return ret

#===========================================

exports.RevokeProofSigGen = class RevokeProofSigGen extends BaseSigGen
  constructor : (args) ->
    @revoke_sig_id = args.sig_id
    super args
    
  _make_binding_eng : (args) ->
    args.revoke = { sig_id : @revoke_sig_id }
    new proofs.Revoke args

  _v_modify_store_arg : (arg) ->
    arg.revoke_sig_id = @revoke_sig_id

  _get_api_endpoint : () -> "sig/revoke"

#===========================================

exports.DnsProofGen = class DnsProofGen extends BaseSigGen

  _binding_klass : () -> proofs.DnsBinding
  constructor : (args) -> 
    @remote_host = args.remote_name_normalized
    super args

  _make_binding_eng : (args) ->
    args.remote_host = @remote_host
    klass = @_binding_klass()
    new klass args

  _v_modify_store_arg : (arg) ->
    arg.remote_host = @remote_host
    arg.type = "web_service_binding.dns"

  instructions : () ->
    "Please save the follows as a DNS TXT entry for #{colors.bold(@remote_host)}"

  display_name : () -> @remote_host
  prompter : () ->
    klass = @_binding_klass()
    return {
      prompt : "DNS Domain to check"
      checker : 
        f     : (i) => @check_name_input(i)
        hint  : klass.name_hint()
    }
  check_name_input : (i) -> @_binding_klass.check_name(i)

  normalize_name : (i, cb) ->
    u = @_binding_klass().parse(i)
    if not u?
      err = new E.ArgsError "Failed to parse #{i} as a DNS domain"
    cb err, u

#===========================================

exports.GenericWebSiteProofGen = class GenericWebSiteProofGen extends BaseSigGen

  _binding_klass : () -> proofs.GenericWebSiteBinding

  constructor : (args) ->
    @remote_host = args.remote_name_normalized
    super args

  _make_binding_eng : (args) ->
    args.remote_host = @remote_host
    klass = @_binding_klass()
    new klass args

  _v_modify_store_arg : (arg) ->
    arg.remote_host = @remote_host
    arg.type = "web_service_binding.generic"

  instructions : () -> 
    "Please save the following file as #{colors.bold @filename()}"

  display_name : () -> @filename()

  filename : (h) ->
    file = proofs.GenericWebSiteScraper.FILE
    (h or @remote_host) + "/" + file

  prompter : () ->
    klass = @_binding_klass()
    return {
      prompt : "Hostname to check"
      checker : 
        f    : (i) => @check_name_input(i)
        hint : klass.name_hint()
    }

  rewrite_hostname : (i) ->
    i = "https://#{i}" unless i.match /^https?:\/\//
    return i

  # The user can enter inputs like "www.foo.com"
  # or "https://www.foo.com" or "http://foo.com"
  check_name_input : (i) ->
    @_binding_klass().check_name(@rewrite_hostname(i))

  get_warnings : ( { remote_name_normalized } ) ->
    f = @filename remote_name_normalized
    return [
      "You'll be asked to post a file available at #{colors.bold(f)}"
    ]

  #----------------

  normalize_name : (i, cb) ->
    n = @rewrite_hostname(i)
    u = @_binding_klass().parse(n)
    ret = null
    if not u?
      err = new E.ArgsError "Failed to parse #{i} is a valid internet host"
    else
      hostname = u.hostname
      args = { endpoint : "remotes/check", args : { hostname } }
      await req.get args, defer err, res
      if err? then # noop
      else if not (protocol = res?.results?.first)? 
        err = new E.HostError "Host #{n} is down; tried 'http' and 'https' protocols"
      else if i.match(/^https:\/\//) and (protocol isnt 'https:')
        err = new E.SecurityError "You specified HTTPS for #{i} but only HTTP is available"
      else
        ret = urlmod.format { protocol , hostname }
    cb err, ret

#===========================================

exports.TwitterProofGen = class TwitterProofGen extends SocialNetworkProofGen
  _binding_klass : () -> proofs.TwitterBinding
  _remote_service_name : () -> "twitter"
  imperative_verb : () -> "tweet"
  display_name : () -> "Twitter"
  instructions : () -> "Please #{colors.bold('publicly')} tweet the following:"

exports.GithubProofGen = class GithubProofGen extends SocialNetworkProofGen
  _binding_klass : () -> proofs.GithubBinding
  _remote_service_name : () -> "github"
  imperative_verb : () -> "post a Gist with"
  display_name : () -> "GitHub"
  instructions : () ->
    "Please #{colors.bold 'publicly'} post the following Gist, and name it #{colors.bold colors.red 'keybase.md'}:"

#===========================================

exports.SignatureEngine = class SignatureEngine 

  #------------

  constructor : ({@km}) ->

  #------------

  get_km : -> @km

  #------------

  box : (msg, cb) ->
    out = {}
    arg = 
      stdin : new Buffer(msg, 'utf8')
      args : [ "-u", @km.get_pgp_key_id(), "--sign", "-a", "--keyid-format", "long" ] 
      quiet : true
    await master_ring().gpg arg, defer err, pgp
    unless err?
      out.pgp = pgp = pgp.toString('utf8')
      [err,msg] = decode pgp
      out.raw = msg.body unless err?
    cb err, out

#================================================================
