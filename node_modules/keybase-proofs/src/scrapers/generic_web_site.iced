{BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants
{decode} = require('pgp-utils').armor
urlmod = require 'url'

#================================================================================


#================================================================================

exports.GenericWebSiteScraper = class GenericWebSiteScraper extends BaseScraper

  @FILE : ".well-known/keybase.txt"
  FILE : GenericWebSiteScraper.FILE

  constructor: (opts) ->
    super opts

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not (args.hostname?)
      new Error "Bad args to generic website proof: no hostname given"
    else if not (args.protocol?)
      new Error "Not protocol given"
    else if not(args.protocol in [ 'https:', 'http:' ] )
      new Error "Unknown protocol given: #{args.protocol}"
    else
      null
  # ---------------------------------------------------------------------------

  make_url : ({protocol, hostname}) ->
    urlmod.format {
      hostname, 
      protocol,
      pathname : @FILE
    }

  # ---------------------------------------------------------------------------

  hunt2 : ({hostname, protocol}, cb) ->
    err = null
    if not hostname? or not protocol? 
      err = new Error "invalid arguments: expected a hostname and protocol"
    else 
      url = @make_url { hostname, protocol }
      out =
        api_url : url
        human_url : url
        remote_id : url
        rc : v_codes.OK
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,hostname,protocol}) ->
    return (api_url.toLowerCase().indexOf(@make_url {hostname, protocol}) >= 0)

  # ---------------------------------------------------------------------------

  # Given a validated signature, check that the payload_text_check matches the sig.
  _validate_text_check : ({signature, proof_text_check }) ->
    [err, msg] = decode signature
    if not err? and ("\n\n" + msg.payload + "\n") isnt proof_text_check
      err = new Error "Bad payload text_check"
    return err

  # ---------------------------------------------------------------------------

  check_status: ({protocol, hostname, api_url, proof_text_check}, cb) ->
    # calls back with a v_code or null if it was ok
    await @_get_url_body {url : api_url}, defer err, rc, raw
    rc = if rc isnt v_codes.OK                             then rc
    else if (@_stripr(raw).indexOf(proof_text_check)) >= 0 then v_codes.OK
    else                                                        v_codes.NOT_FOUND
    cb err, rc

#================================================================================

