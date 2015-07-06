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
scrapers = require './scrapers'

#===========================================

url_reencode = (url) ->
  # Use '+'-encoding for a smaller URL
  # Replace '(', ")" and "'" so that URL-detection works in Linux
  # Padding is not needed now, but might be in the future depending on
  # changes we make
  pad2 = (x) -> if x.length is 1 then "0#{x}" else x
  url.replace(/%20/g, '+').
      replace(/[()']/g, (c) -> "%" + pad2(c.charCodeAt(0).toString(16)))

#===========================================

class BaseSigGen

  constructor : ({@km, @eldest_kid, @client, @supersede, @merkle_root, @revoke_sig_ids}) ->

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
    arg = {
      sig_eng : (new SignatureEngine {@km} ),
      @seqno,
      @prev,
      host : constants.canonical_host,
      user :
        local :
          uid : session.get_uid()
          username : env().get_username()
      @client,
      @merkle_root,
      @eldest_kid,
    }
    # Recent addition --- any signature can carry a revocation with it...
    arg.revoke = { sig_ids } if (sig_ids = @revoke_sig_ids)?
    @_make_binding_eng arg

  #---------

  _do_signature : (cb) ->
    @eng = @_get_binding_eng()
    await @eng.generate defer err, @sig
    cb err

  #---------

  _v_modify_store_arg : (arg) ->
  _get_api_endpoint : () -> "sig/post"

  #---------

  expect_proof_text : () -> false

  #---------

  _store_signature : (cb) ->
    args =
      sig : @sig.pgp
      sig_id_base : @sig.id
      sig_id_short : @sig.short_id
      is_remote_proof : true
      supersede : @supersede
    @_v_modify_store_arg args
    endpoint = @_get_api_endpoint()
    log.debug "+ storing signature:"
    log.debug "| writing to #{endpoint}"
    log.debug "| with args #{JSON.stringify args}"

    await req.post { need_cookie : true, endpoint, args }, defer err, body

    unless err?
      { @proof_text, @proof_id, @sig_id, @proof_metadata } = body
      log.debug "| reply with value: #{JSON.stringify body}"

    if not(err?) and @expect_proof_text()
      if not @proof_text?
        err = new Error "Server didn't reply with proof text"
      else
        await @eng.sanity_check_proof_text { args, @proof_text }, defer err
        if err?
          log.warn "Server replied with a suspect proof text"

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

  show_proof_text : () -> @proof_text

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
  do_recheck : (i) -> true
  do_precheck : ( { remote_name_normalized }, cb) -> cb null

  #-----------------------

  make_retry_msg : (code) ->
    "Didn't find the posted proof."

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

exports.CryptocurrencySigGen = class CryptocurrencySigGen extends BaseSigGen

  constructor : (args) ->
    {@cryptocurrency} = args
    super args

  _make_binding_eng : (arg) ->
    arg.cryptocurrency = @cryptocurrency
    new proofs.Cryptocurrency arg

  _v_modify_store_arg : (arg) ->
    arg.type = "cryptocurrency"
    arg.is_remote_proof = false

#===========================================

exports.AnnouncementSigGen = class AnnouncementSigGen extends BaseSigGen

  constructor : (args) ->
    {@announcement} = args
    super args

  _make_binding_eng : (arg) ->
    arg.announcement = @announcement
    new proofs.Announcement arg

  _v_modify_store_arg : (arg) ->
    arg.type = "announcement"
    arg.is_remote_proof = false

#===========================================

exports.TrackerProofGen = class TrackerProofGen extends BaseSigGen

  constructor : (args) ->
    {@prev, @seqno, @uid, @track} = args
    super args

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

  constructor : (args) ->
    {@uid, @untrack, @seqno, @prev} = args
    super args

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

  get_prompt : () -> "Your username on #{@display_name()}"

  prompter : () ->
    klass = @_binding_klass()
    ret = {
      prompt  : @get_prompt()
      checker :
        f         : klass.check_name
        hint      : klass.name_hint()
        normalize : klass.normalize_name
    }
    return ret

  expect_proof_text : () -> true

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
    search = [ @remote_host, [ "_keybase", @remote_host ].join(".") ]
    hosts = (colors.bold(h) for h in search).join(" OR ")
    "Please save the following as a DNS TXT entry for #{hosts}"

  display_name : () -> @remote_host
  prompter : () ->
    klass = @_binding_klass()
    return {
      prompt : "DNS Domain to check"
      checker :
        f     : (i) => @check_name_input(i)
        hint  : klass.name_hint()
    }
  check_name_input : (i) -> @_binding_klass().check_name(i)

  normalize_name : (i, cb) ->
    u = @_binding_klass().parse(i)
    if not u?
      err = new E.ArgsError "Failed to parse #{i} as a DNS domain"
    cb err, u

  do_recheck : (i) ->
    log.info "We couldn't find a DNS proof for #{@remote_host}.....#{colors.bold('yet')}"
    log.info "DNS propagation can be slow; we'll keep trying and email you the result."
    false

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

  styled_filenames : (h) ->
    files = @filenames h
    (colors.bold(f) for f in files).join("\n  or ")

  instructions : () ->
    "Please save the following file as #{@styled_filenames()}"

  display_name : () -> @filenames().join(' OR ' )

  filenames : (h) ->
    files = proofs.GenericWebSiteScraper.FILES
    ((h or @remote_host) + "/" + f) for f in files

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
    return [
      "You'll be asked to post a file available at",
      "     " + @styled_filenames(remote_name_normalized)
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

  #----------------

  expect_proof_text : () -> true

#===========================================

exports.TwitterProofGen = class TwitterProofGen extends SocialNetworkProofGen
  _binding_klass : () -> proofs.TwitterBinding
  _remote_service_name : () -> "twitter"
  imperative_verb : () -> "tweet"
  display_name : () -> "Twitter"
  instructions : () -> "Please #{colors.bold('publicly')} tweet the following:"

  make_retry_msg : (status) ->
    switch status
      when proofs.constants.v_codes.PERMISSION_DENIED
        "Permission denied! We can't support private feeds."
      else
        super()

#===========================================

exports.RedditProofGen = class RedditProofGen extends SocialNetworkProofGen
  _binding_klass : () -> proofs.RedditBinding
  _remote_service_name : () -> "reddit"
  imperative_verb : () -> "post"
  display_name : () -> "Reddit"
  instructions : () -> "Please click on the following link to post to Reddit:"

  show_proof_text : () ->
    body = @proof_text
    title = @proof_metadata.title
    url_reencode urlmod.format {
      protocol : "https"
      host : "www.reddit.com"
      pathname : "/r/KeybaseProofs/submit"
      query :
        title : @proof_metadata.title
        text : @proof_text
    }

#===========================================

exports.GithubProofGen = class GithubProofGen extends SocialNetworkProofGen
  _binding_klass : () -> proofs.GithubBinding
  _remote_service_name : () -> "github"
  imperative_verb : () -> "post a Gist with"
  display_name : () -> "GitHub"
  instructions : () ->
    "Please #{colors.bold 'publicly'} post the following Gist, and name it #{colors.bold colors.red 'keybase.md'}:"

  make_retry_msg : (status) ->
    switch status
      when proofs.constants.v_codes.PERMISSION_DENIED
        "Permission denied! Make sure your Gist is public"
      else
        super()

#===========================================

exports.HackerNewsProofGen = class HackerNewsProofGen extends SocialNetworkProofGen
  _binding_klass : () -> proofs.HackerNewsBinding
  _remote_service_name : () -> "hackernews"
  imperative_verb : () -> "update your profile with"
  display_name : () -> "HackerNews"
  instructions : () ->
    "Please edit your HackerNews profile to contain the following text. Click here: https://news.ycombinator.com/user?id=#{@remote_username}"

  do_recheck : (i) ->
    log.info "We couldn't find a posted proof for #{@remote_username}.....#{colors.bold('yet')}"
    if i < 3
      log.info "HackerNews's API is slow to update, so be patient...try again?"
      true
    else
      log.info "We'll keep trying and let you know!"
      false
  get_warnings : ( { remote_name_normalized } ) -> []

  do_precheck : ( { remote_name_normalized } , cb) ->
    scraper = (new scrapers.HackerNews).make_scraper()
    await scraper.get_karma remote_name_normalized, defer err, json
    if err? then # noop
    else if not(json?)
      log.warn "#{colors.bold("ATTENTION")}: HackerNews only publishes users to their API with #{colors.bold("karma > 1")}."
      log.warn "Your account #{colors.bold(remote_name_normalized)} doesn't qualify, or doesn't exist!"
      err = new E.KarmaError "Insufficient HackerNews karma (>= 2 needed) or bad username (case sensitive!)"
    cb err

  get_prompt : () -> "Your username on #{@display_name()} (**case sensitive**)"

#===========================================

exports.CoinbaseProofGen = class CoinbaseProofGen extends SocialNetworkProofGen
  _binding_klass : () -> proofs.CoinbaseBinding
  _remote_service_name : () -> "coinbase"
  imperative_verb : () -> "update your Coinbase profile with"
  display_name : () -> "coinbase"
  instructions : () ->
    "Please update your Coinbase profile to show this proof. Click here: https://coinbase.com/#{@remote_username}/public-key"

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
