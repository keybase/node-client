{BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants

#================================================================================

exports.BitbucketScraper = class BitbucketScraper extends BaseScraper

  constructor: (opts) ->
    @auth = opts.auth
    super opts

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not(args.username?)
      new Error "Bad args to Bitbucket proof: no username given"
    else if not (args.name?) or (args.name isnt 'bitbucket')
      new Error "Bad args to Bitbucket proof: type is #{args.name}"
    else
      null

  # ---------------------------------------------------------------------------

  hunt2 : ({username, proof_text_check, name}, cb) ->

    # calls back with rc, out
    rc       = v_codes.OK
    out      = {}

    return cb(err,out) if (err = @_check_args { username, name })?

    url = "https://api.bitbucket.org/2.0/snippets/#{username}"
    await @_get_body url, true, defer err, rc, json
    @log "| search index #{url} -> #{rc}"
    if rc is v_codes.OK
      rc = v_codes.NOT_FOUND
      for snippet in json.values
        await @_search_snippet { snippet, proof_text_check }, defer out
        break if out.rc is v_codes.OK
    out.rc or= rc
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,username}) ->
    rxx = new RegExp("^https://api.bitbucket.org/2.0/snippets/#{username}/", "i")
    return (api_url? and api_url.match(rxx));

  # ---------------------------------------------------------------------------

  _search_snippet : ({snippet, proof_text_check}, cb) ->
    out = {}
    @log "+ Searching snippet #{JSON.stringify snippet}"
    if not (u = snippet?.links?.self?.href)?
      @log "| snippet didn't have a URL"
      rc = v_codes.FAILED_PARSE
    else
      await @_get_body u, true, defer err, rc, json
      if err?
        @log "| snippet #{u} failed to return a files list; #{err.toString()}"
        rc = v_codes.HTTP_OTHER
      else if rc isnt v_codes.OK
        @log "| snippet #{u} failed to return a files list; rc=#{rc}"
      else if not json.files?
        @log "| snippet didn't have a files section"
        rc = v_codes.FAILED_PARSE
      else
        rc = v_codes.NOT_FOUND
        for filename, file of json.files when (ul = file?.links?.self?.href)?
          await @_get_body ul, false, defer err, rc2, content
          if err?
            @log "| search #{filename} (#{ul}): #{err.toString()}"
          else if rc2 isnt v_codes.OK
            @log "| search #{filename} (#{ul}): non-OK code #{rc2}"
          else if (id = @_stripr(content).indexOf(proof_text_check)) < 0
            @log "| search #{filename} (#{ul}) -> content miss"
          else
            @log "| search #{filename} (#{ul})-> found"
            rc = v_codes.OK
            out =
              api_url : file.links.self.href
              remote_id : snippet.id
              human_url : file.links.html.href
            break
    @log "- search snippet #{u} -> #{rc}"
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
      auth : @auth
    args.json = 1 if json
    @_get_url_body args, cb

#================================================================================
