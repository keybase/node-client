{BaseScraper} = require './base'
{constants} = require '../constants'
{v_codes} = constants
{make_ids,proof_text_check_to_med_id} = require '../base'
{decode_sig} = require('kbpgp').ukm

#================================================================================

exports.HackerNewsScraper = class HackerNewsScraper extends BaseScraper

  constructor: (opts) ->
    super opts

  # ---------------------------------------------------------------------------

  _check_args : (args) ->
    if not(args.username?)
      new Error "Bad args to HackerNews proof: no username given"
    else if not (args.name?) or (args.name isnt 'hackernews')
      new Error "Bad args to HackerNews proof: type is #{args.name}"
    else
      null

  # ---------------------------------------------------------------------------


  # ---------------------------------------------------------------------------

  api_base : (username) -> "https://hacker-news.firebaseio.com/v0/user/#{username}"
  api_url : (username) -> @api_base(username) + "/about.json"
  karma_url : (username) -> @api_base(username) + "/karma.json"
  human_url : (username) -> "https://news.ycombinator.com/user?id=#{username}"

  # ---------------------------------------------------------------------------

  get_karma : (username, cb) ->
    await @_get_url_body { url : @karma_url(username), json : true }, defer err, rc, json
    cb err, json

  # ---------------------------------------------------------------------------

  hunt2 : ({username, name, proof_text_check}, cb) ->
    # calls back with err, out

    out      = {}
    rc       = v_codes.OK

    unless (err = @_check_args { username, name })?
      out =
        rc : rc
        api_url : @api_url(username)
        human_url : @human_url(username)
        remote_id : username
    cb err, out

  # ---------------------------------------------------------------------------

  _check_api_url : ({api_url,username}) -> api_url is @api_url(username)

  # ---------------------------------------------------------------------------

  # Given a validated signature, check that the payload_text_check matches the sig.
  _validate_text_check : ({signature, proof_text_check }) ->
    [err, msg] = decode_sig { armored: signature }
    if not err?
      {med_id} = make_ids msg.body
      if med_id isnt proof_text_check
        err = new Error "Bad payload text_check"
    return err

  # ---------------------------------------------------------------------------

  check_status: ({username, api_url, proof_text_check, remote_id}, cb) ->

    # calls back with a v_code or null if it was ok
    await @_get_url_body {url : api_url }, defer err, rc, html

    if rc is v_codes.OK
      search_for = proof_text_check
      if html.indexOf(search_for) < 0 then rc = v_codes.NOT_FOUND

    cb err, rc

#================================================================================
