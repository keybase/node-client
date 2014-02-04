proofs = require 'keybase-proofs'
{make_esc} = require 'iced-error'
req = require './req'
{constants} = require './constants'
session = require './session'
{env} = require './env'
log = require './log'
{master_ring} = require './keyring'
{decode} = require('pgp-utils').armor

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
          uid : env().get_uid()
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

class RemoteServiceProofGen extends BaseSigGen
  constructor : (args) ->
    @remote_username = args.remote_username
    super args

  _make_binding_eng : (args) ->
    args.user.remote = @remote_username
    klass = @_binding_klass()
    new klass args

  _v_modify_store_arg : (arg) ->
    arg.remote_username = @remote_username
    arg.type = "web_service_binding." + @_remote_service_name()

#===========================================

exports.TwitterProofGen = class TwitterProofGen extends RemoteServiceProofGen
  _binding_klass : () -> proofs.TwitterBinding
  _remote_service_name : () -> "twitter"
  imperative_verb : () -> "tweet"
  display_name : () -> "Twitter"

exports.GithubProofGen = class GithubProofGen extends RemoteServiceProofGen
  _binding_klass : () -> proofs.GithubBinding
  _remote_service_name : () -> "github"
  imperative_verb : () -> "post a Gist with"
  display_name : () -> "GitHub"

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
