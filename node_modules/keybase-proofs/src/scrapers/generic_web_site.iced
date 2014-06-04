{BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants
{decode} = require('pgp-utils').armor
urlmod = require 'url'

#================================================================================

exports.GenericWebSiteScraper = class GenericWebSiteScraper extends BaseScraper

  @FILES : [ ".well-known/keybase.txt", "keybase.txt" ]
  FILES : GenericWebSiteScraper.FILES

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

  make_url : ({protocol, hostname, pathname}) ->
    urlmod.format {
      hostname, 
      protocol,
      pathname
    }

  # ---------------------------------------------------------------------------

  _check_url : ( { url, proof_text_check }, cb) ->
    # calls back with a v_code or null if it was ok
    await @_get_url_body {url }, defer err, rc, raw
    rc = if rc isnt v_codes.OK                             then rc
    else if (@_stripr(raw).indexOf(proof_text_check)) >= 0 then v_codes.OK
    else                                                        v_codes.NOT_FOUND
    cb err, rc

  # ---------------------------------------------------------------------------

  hunt2 : ({hostname, protocol, proof_text_check}, cb) ->
    err = null
    out = {}
    err = null
    rc = v_codes.OK
    if not hostname? or not protocol? 
      err = new Error "invalid arguments: expected a hostname and protocol"
    else 
      for f in @FILES
        url = @make_url { hostname, protocol , pathname : f }
        await @_check_url { url , proof_text_check }, defer err, rc
        @log "| hunt #{url} -> #{rc}"
        if rc is v_codes.OK
          out =
            api_url : url
            human_url : url
            remote_id : url
          break
        else if rc in [ v_codes.HTTP_400,  v_codes.HTTP_500, 
                        v_codes.NOT_FOUND, v_codes.PERMISSION_DENIED ]
          continue
        else
          break
    out.rc = rc
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,hostname,protocol}) ->
    for f in @FILES
      if (api_url.toLowerCase().indexOf(@make_url {hostname, protocol, pathname : f}) >= 0) 
        return true
    return false

  # ---------------------------------------------------------------------------

  # Given a validated signature, check that the payload_text_check matches the sig.
  _validate_text_check : ({signature, proof_text_check }) ->
    [err, msg] = decode signature
    if not err? and ("\n\n" + msg.payload + "\n") isnt proof_text_check
      err = new Error "Bad payload text_check"
    return err

  # ---------------------------------------------------------------------------

  check_status: ({protocol, hostname, api_url, proof_text_check}, cb) ->
    await @_check_url { url : api_url, proof_text_check }, defer err, rc
    cb err, rc

#================================================================================

