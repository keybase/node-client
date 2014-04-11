{BaseScraper} = require './base'
{make_ids} = require '../base'
{constants} = require '../constants'
{Lock} = require '../util'
{v_codes} = constants
{decode} = require('pgp-utils').armor
urlmod = require 'url'

#================================================================================

sncmp = (a,b) ->
  if not a? or not b? then false
  else
    a = ("" + a).toLowerCase()
    b = ("" + b).toLowerCase()
    (a is b)

#================================================================================

class BearerToken

  #----------------

  constructor : ({@base}) ->
    @_tok = null
    @_created = 0
    @_lock = new Lock()
    @auth = @base.auth

  #----------------

  get : (cb) ->
    await @_lock.acquire defer()
    err = null
    now = Math.floor(Date.now() / 1000)

    if not (res = @_tok)? or (now - @_created > @auth.lifespan)

      @base.log "+ Request for bearer token"

      # Very crypto!  Not sure why this is done, but it's done
      cred = (new Buffer [ @auth.key, @auth.secret].join(":")).toString('base64')

      opts = 
        url : "https://api.twitter.com/oauth2/token"
        headers : 
          Authorization : "Basic #{cred}"
        form :
          grant_type : "client_credentials"
        method : "POST"

      await @base._get_url_body opts, defer err, rc, body

      if err?
        @base.logl 'error', "In getting bearer_token: #{err.message}"
      else if (rc isnt v_codes.OK)
        @base.logl 'error', "HTTP error in getting bearer token: #{rc}"
        err = new Error "HTTP error: #{rc}"
      else
        try
          body = JSON.parse body
        catch e
          @base.logl 'warn', "Could not parse JSON reply: #{e}"
          err = e

      if err? then # noop
      else if not (tok = body.access_token)?
        @base.logl 'warn', "No access token found in reply"
        err = new Error "Twitter error: no access token"
      else
        @_tok = tok
        @_created = Math.floor(Date.now() / 1000)
        res = @_tok

      @base.log "- Request for bearer token -> #{err}"

    @_lock.release()
    cb err, res

#================================================================================

_bearer_token = null
bearer_token = ({base}) ->
  unless _bearer_token
    _bearer_token = new BearerToken { base }
  return _bearer_token

#================================================================================

exports.TwitterScraper = class TwitterScraper extends BaseScraper

  constructor: (opts) ->
    @auth = opts.auth
    super opts

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not(args.username?) 
      new Error "Bad args to Twitter proof: no username given"
    else if not (args.name?) or (args.name isnt 'twitter')
      new Error "Bad args to Twitter proof: type is #{args.name}"
    else
      null

  # ---------------------------------------------------------------------------

  hunt2 : ({username, name, proof_text_check}, cb) ->
    # calls back with err, out
    out      = {}
    rc       = v_codes.OK

    return cb(err) if (err = @_check_args { username, name })?

    u = urlmod.format {
      host : "api.twitter.com"
      protocol : "https:"
      pathname : "/1.1/statuses/user_timeline.json"
      query :
        count : 100
        screen_name : username
    }

    await @_get_body_api { url : u }, defer err, rc, json
    @log "| search index #{u} -> #{rc}"
    if rc isnt v_codes.OK then #noop
    else if not json? or (json.length is 0) then rc = v_codes.EMPTY_JSON
    else
      for {text, id_str},i in json
        if (@find_sig_in_tweet { inside : text, proof_text_check }) is v_codes.OK
          @log "| found valid tweet in stream @ #{i}"
          rc = v_codes.OK
          remote_id = id_str
          api_url = human_url = @_id_to_url username, remote_id
          out = { remote_id, api_url, human_url }
          break
    out.rc = rc
    cb err, out

  # ---------------------------------------------------------------------------

  _id_to_url : (username, status_id) ->
    "https://twitter.com/#{username}/status/#{status_id}"

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,username}) ->
    return (api_url.indexOf("https://twitter.com/#{username}/") is 0)

  # ---------------------------------------------------------------------------

  # Given a validated signature, check that the proof_text_check matches the sig.
  _validate_text_check : ({signature, proof_text_check }) ->
    [err, msg] = decode signature
    if not err?
      {short_id} = make_ids msg.body
      if proof_text_check.indexOf(" " + short_id + " ")  < 0
        err = new Error "Cannot find #{short_id} in #{proof_text_check}"
    return err

  # ---------------------------------------------------------------------------

  find_sig_in_tweet : ({inside, tweet_p, proof_text_check}) ->

    if tweet_p? and not inside? 
      inside = tweet_p.text()
      html = tweet_p.html()
    else
      html = null
        
    x = /^(@[a-zA-Z0-9_-]+\s+)/
    @log "+ Checking tweet '#{inside} for signature '#{proof_text_check}'"
    @log "| html is: #{html}" if html?
    while (m = inside.match(x))?
      p = m[1]
      inside = inside[p.length...]
      @log "| Stripping off @prefix: #{p}"
    rc = if inside.indexOf(proof_text_check) is 0 then v_codes.OK else v_codes.DELETED
    @log "- Result -> #{rc}"
    return rc

  # ---------------------------------------------------------------------------

  check_status: ({username, api_url, proof_text_check, remote_id}, cb) ->
    # calls back with a v_code or null if it was ok
    await @_get_url_body { url : api_url }, defer err, rc, html

    if rc is v_codes.OK

      $ = @libs.cheerio.load html
      #
      # only look inside the permalink tweet container
      # 
      div = $('.permalink-tweet-container .permalink-tweet')
      if not div.length
        rc = v_codes.FAILED_PARSE
      else
        div = div.first()

        #
        # make sure both the username and tweet id match our query, 
        # in case twitter printed other tweets into the page
        # inside this container
        #
        rc = if not(sncmp(username, div.data('screenName'))) then v_codes.BAD_USERNAME
        else if (("" + remote_id) isnt ("" + div.data('tweetId'))) then v_codes.BAD_REMOTE_ID
        else if not (p = div.find('p.tweet-text'))? or not p.length then v_codes.MISSING
        else @find_sig_in_tweet { tweet_p : p.first(), proof_text_check }

    cb err, rc

  # ---------------------------------------------------------------------------

  _get_bearer_token : (cb) ->
    bt = bearer_token { base : @ }
    await bt.get defer err, tok
    rc = if err? then v_codes.AUTH_FAILED else v_codes.OK
    cb err, rc, tok

  # ---------------------------------------------------------------------------

  # Only the hunter needs this 
  _get_body_api : ({url}, cb) ->
    rc = body = err = null
    await @_get_bearer_token defer err, rc, tok
    unless err?
      @log "| HTTP API request for URL '#{url}'"
      args =
        url : url
        headers : 
          Authorization : "Bearer #{tok}"
          method : "GET"
        json : true
      await @_get_url_body args, defer err, rc, body
    cb err, rc, body

#================================================================================
