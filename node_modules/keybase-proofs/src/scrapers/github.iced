{BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants
{decode} = require('pgp-utils').armor

#================================================================================

exports.GithubScraper = class GithubScraper extends BaseScraper

  constructor: (opts) ->
    @auth = opts.auth
    super opts

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not(args.username?) 
      new Error "Bad args to Github proof: no username given"
    else if not (args.name?) or (args.name isnt 'github')
      new Error "Bad args to Github proof: type is #{args.name}"
    else
      null

  # ---------------------------------------------------------------------------

  hunt2 : ({username, proof_text_check, name}, cb) ->

    # calls back with rc, out
    rc       = v_codes.OK
    out      = {}

    return cb(err) if (err = @_check_args { username, name })?

    url = "https://api.github.com/users/#{username}/gists"
    await @_get_body url, true, defer err, rc, json
    @log "| search index #{url} -> #{rc}"
    if rc is v_codes.OK
      rc = v_codes.NOT_FOUND
      for gist in json 
        await @_search_gist { gist, proof_text_check }, defer out
        break if out.rc is v_codes.OK
    out.rc or= rc
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,username}) ->
    rxx = new RegExp("^https://gist.github(usercontent)?\\.com/#{username}/", "i")
    return (api_url? and api_url.match(rxx));

  # ---------------------------------------------------------------------------

  # Given a validated signature, check that the payload_text_check matches the sig.
  _validate_text_check : ({signature, proof_text_check }) ->
    [err, msg] = decode signature
    if not err? and ("\n\n" + msg.payload + "\n") isnt proof_text_check
      err = new Error "Bad payload text_check"
    return err

  # ---------------------------------------------------------------------------

  _search_gist : ({gist, proof_text_check}, cb) ->
    out = {}
    if not (u = gist.url)? 
      @log "| gist didn't have a URL"
      rc = v_codes.FAILED_PARSE
    else
      await @_get_body u, true, defer err, rc, json
      if rc isnt v_codes.OK then # noop
      else if not json.files? then rc = v_codes.FAILED_PARSE
      else
        rc = v_codes.NOT_FOUND
        for filename, file of json.files when (content = file.content)?
          if (id = @_stripr(content).indexOf(proof_text_check)) >= 0
            @log "| search #{filename} -> found"
            rc = v_codes.OK
            out = 
              api_url : file.raw_url
              remote_id : gist.id
              human_url : gist.html_url
            break
          else
            @log "| search #{filename} -> miss"
      @log "| search gist #{u} -> #{rc}"
    out.rc = rc
    cb out

  # ---------------------------------------------------------------------------

  check_status: ({username, api_url, proof_text_check, remote_id}, cb) ->

    # calls back with a v_code or null if it was ok
    await @_get_body api_url, false, defer err, rc, raw

    rc = if rc isnt v_codes.OK                  then rc
    else if (raw.indexOf proof_text_check) >= 0 then v_codes.OK
    else                                             v_codes.NOT_FOUND
    cb err, rc

  # ---------------------------------------------------------------------------

  _get_body : (url, json, cb) ->
    @log "| HTTP request for URL '#{url}'"
    args =
      url : url
      headers : 
        "User-Agent" : constants.user_agent
      auth : @auth
    args.json = 1 if json
    @_get_url_body args, cb

#================================================================================

