{sncmp,BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants
{Lock} = require 'iced-lock'
{make_esc} = require 'iced-error'
{make_ids} = require '../base'

#================================================================================

PREFIX = "https://www.reddit.com"
SUBREDDIT = PREFIX + "/r/keybaseproofs"

#================================================================================

proof_text_check_to_med_id = (proof_text_check) ->
  {med_id} = make_ids(new Buffer proof_text_check, 'base64')
  med_id

#================================================================================

class GlobalHunter

  constructor : () ->
    @_startup_window = 20*60 # on startup, go back 20 minutes
    @_delay = 5000 # always wait 5s = 5000msec
    @_running = false
    @_lock = new Lock
    @_cache = {}
    @_last_rc = null
    @_most_recent = null

  #---------------------------

  index : (lst) ->
    for el in lst
      data = el.data
      author = data.author.toLowerCase()
      if not (m = data.title.match /\(([a-zA-Z0-9_-]{43})\)/)? or not (id = m[1])?
        @_scraper.log "| [Reddit] Unindexable: #{data.title}"
      else if not @_cache[id]?
        @_scraper.log "| [Reddit] Indexing #{author}/#{id}: #{data.name} @ #{data.created_utc} (#{PREFIX}#{data.permalink})"
        @_cache[id] = el

  #---------------------------

  go_back : (stop, cb) ->
    @_scraper.log "+ [Reddit] rescraping to #{stop}"
    after = null
    go = true
    first = null
    esc = make_esc cb, "go_back"
    while go
      args =
        url : SUBREDDIT + "/.json"
        json : true
        qs: 
          count : 25
          cachebust : Math.random()
      args.qs.after = after if after?
      @_scraper.log "+ [Reddit] Start at after=#{after}"
      await @_scraper._get_url_body args, defer err, @_last_rc, body
      after = body.data.after
      posts = body.data.children
      @_scraper.log "- [Reddit] Got back #{posts.length} posts"
      if posts.length
        @index posts
        first = posts[0] unless first?
      go = false if not after? or not posts.length or posts[-1...][0].data.created_utc < stop
    @_most_recent = first.data.created_utc if first?
    @_scraper.log "- [Reddit] rescraped; most_recent is now #{@_most_recent}"
    cb null

  #---------------------------

  scrape : (cb) ->
    stop = if @_most_recent? then @_most_recent
    else (Math.ceil(Date.now() / 1000) - @_startup_window)
    await @go_back stop, defer err
    cb err

  #---------------------------

  start_scraper_loop : ({scraper}, cb) ->
    @_scraper = scraper
    await @scrape defer err
    @_running = true
    cb err
    loop
      await setTimeout defer(), @_delay
      await @scrape defer()

  #---------------------------

  find : ( {scraper, med_id}, cb) ->
    err = out = null
    await @_lock.acquire defer()
    if not @_running
      await @start_scraper_loop {scraper}, defer err
    @_lock.release()
    rc = if err? then @_last_rc 
    else if (out = @_cache[med_id])? then v_codes.OK
    else v_codes.NOT_FOUND
    cb err, rc, out

#================================================================================

_global_hunter = new GlobalHunter()

#================================================================================

exports.RedditScraper = class RedditScraper extends BaseScraper

  constructor: (opts) ->
    super opts

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not(args.username?) 
      new Error "Bad args to Reddit proof: no username given"
    else if not (args.name?) or (args.name isnt 'reddit')
      new Error "Bad args to Reddit proof: type is #{args.name}"
    else
      null

  # ---------------------------------------------------------------------------

  hunt2 : ({username, proof_text_check, name}, cb) ->
    rc  = v_codes.OK
    out = {}
    if (err = @_check_args { username, name })?
      rc = v_codes.BAD_ARGS
    else
      med_id = proof_text_check_to_med_id proof_text_check
      await _global_hunter.find { scraper : @, med_id}, defer err, rc, json
      if rc isnt v_codes.OK then # noop
      else if not sncmp(json.data.author,username)
        rc = v_codes.BAD_USERNAME
      else
        out =
          api_url : PREFIX + json.data.permalink + ".json"
          human_url : PREFIX + json.data.permalink
          remote_id : json.data.name
    out.rc = rc
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,username}) ->
    rxx = new RegExp("^#{SUBREDDIT}", "i")
    return (api_url? and api_url.match(rxx));

  # ---------------------------------------------------------------------------

  unpack_data : (json) ->
    if (json[0]?.kind is 'Listing') and ((parent = json[0]?.data?.children?[0])?.kind is 't3')
      parent.data
    else
      null

  # ---------------------------------------------------------------------------

  check_data : ({json, username, proof_text_check}) ->
    med_id = proof_text_check_to_med_id proof_text_check
    if not (json.subreddit? and json.author? and json.selftext? and json.title) 
      v_codes.CONTENT_MISSING
    else if (json.subreddit.toLowerCase() isnt 'keybaseproofs') 
      v_codes.SERVICE_ERROR
    else if not sncmp(json.author, username) then v_codes.BAD_USERNAME
    else if (json.title.indexOf(med_id) < 0) 
      v_codes.TITLE_NOT_FOUND
    else 

      # strip leading spaces on the input document, so we can look for the target
      # sig on the first column.
      lstrip = (line) -> if (m = line.match(/^\s+(.*?)$/))? then m[1] else line
      body = ( lstrip(line) for line in json.selftext.split("\n")).join("\n")

      if body.indexOf(proof_text_check) < 0
        v_codes.TEXT_NOT_FOUND
      else v_codes.OK

  # ---------------------------------------------------------------------------

  check_status: ({username, api_url, proof_text_check, remote_id}, cb) ->

    # calls back with a v_code or null if it was ok
    await @_get_url_body { url : api_url , json : true }, defer err, rc, json

    rc = if rc isnt v_codes.OK then rc
    else if not (dat = @unpack_data(json)) then v_codes.CONTENT_FAILURE
    else @check_data {json : dat, username, proof_text_check }
    cb err, rc

#================================================================================

