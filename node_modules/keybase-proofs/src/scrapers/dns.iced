{BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants
{decode} = require('pgp-utils').armor
urlmod = require 'url'
{make_ids} = require '../base'
urlmod = require 'url'
dns = require 'dns'

#================================================================================

exports.DnsScraper = class DnsScraper extends BaseScraper

  # ---------------------------------------------------------------------------

  constructor: (opts) ->
    super opts

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not (args.domain?) then new Error "Bad args to DNS proof: no domain given"
    else null

  # ---------------------------------------------------------------------------

  make_url : ({domain}) -> "dns://#{domain.toLowerCase()}"
  url_to_domain : (u) -> urlmod.parse(u)?.hostname

  # ---------------------------------------------------------------------------

  hunt2 : ({domain}, cb) ->
    err = null
    out = {}
    if not domain?
      err = new Error "invalid arguments: expected a domain"
    else 
      url = @make_url { domain }
      out =
        api_url   : url
        human_url : url
        remote_id : url
        rc        : v_codes.OK
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,domain}) ->
    return (api_url.toLowerCase().indexOf(@make_url {domain}) >= 0)

  # ---------------------------------------------------------------------------

  # Given a validated signature, check that the payload_text_check matches the sig.
  _validate_text_check : ({signature, proof_text_check }) ->
    [err, msg] = decode signature
    if not err?
      {med_id} = make_ids msg.body
      if proof_text_check.indexOf(med_id) < 0
        err = new Error "Bad payload text_check"
    return err

  # ---------------------------------------------------------------------------

  check_status : ({api_url, proof_text_check}, cb) ->
    rc = err = null
    if not (domain = @url_to_domain(api_url))?
      err = new Error "no domain found in URL #{api_url}"
      rc = v_codes.CONTENT_FAILURE
    else
      search_domains = [ domain, [ "_keybase", domain].join(".") ]
      for d in search_domains
        await @_check_status { domain : d, proof_text_check }, defer err, rc
        break if (rc is v_codes.OK)
    cb err, rc

  # ---------------------------------------------------------------------------

  # calls back with a v_code or null if it was ok
  _check_status: ({domain, proof_text_check}, cb) ->
    @log "+ DNS check for #{domain}"
    await dns.resolveTxt domain, defer err, records
    rc = if err?
      @log "| DNS error: #{err}"
      v_codes.DNS_ERROR
    else if (proof_text_check in records) then v_codes.OK
    else
      @log "| DNS failed; found TXT entries: #{JSON.stringify records}"
      v_codes.NOT_FOUND
    @log "- DNS check for #{domain} -> #{rc}"
    cb err, rc

#================================================================================

