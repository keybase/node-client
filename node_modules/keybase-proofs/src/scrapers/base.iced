{constants} = require '../constants'
{v_codes} = constants
pkg = require '../../package.json'
{decode_sig} = require('kbpgp').ukm
{space_normalize} = require '../util'

#==============================================================

exports.user_agent = user_agent = constants.user_agent + pkg.version

#==============================================================

class BaseScraper
  constructor : ({@libs, log_level, @proxy, @ca}) ->
    @log_level = log_level or "debug"

  hunt : (username, proof_check_text, cb) -> hunt2 { username, proof_check_text }, cb
  hunt2 : (args, cb) -> cb new Error "unimplemented"
  id_to_url : (username, status_id) ->
  check_status : ({username, url, signature, status_id}, cb) ->
  _check_args : () -> new Error "unimplemented"

  #-------------------------------------------------------------

  # Can we trust it over Tor? HTTP and DNS aren't trustworthy over
  # Tor, but HTTPS is.
  get_tor_error : (args) -> [ null, v_codes.OK ]

  #-------------------------------------------------------------

  logl : (level, msg) ->
    if (k = @libs.log)? then k[level](msg)

  #-------------------------------------------------------------

  log : (msg) ->
    if (k = @libs.log)? and @log_level? then k[@log_level](msg)

  #-------------------------------------------------------------

  validate : (args, cb) ->
    err = null
    rc = null
    if (err = @_check_args(args)) then # noop
    else if not @_check_api_url args
      err = new Error "check url failed for #{JSON.stringify args}"
    else
      err = @_validate_text_check args
    unless err?
      await @check_status args, defer err, rc
    cb err, rc

  #-------------------------------------------------------------

  # Given a validated signature, check that the payload_text_check matches the sig.
  _validate_text_check : ({signature, proof_text_check }) ->
    [err, msg] = decode_sig { armored: signature }
    # PGP sigs need some newline massaging here, but NaCl sigs don't.
    if not err? and ("\n\n" + msg.payload + "\n") isnt proof_text_check and msg.payload isnt proof_text_check
      err = new Error "Bad payload text_check"
    return err

  #-------------------------------------------------------------

  # Convert away from MS-dos style encoding...
  _stripr : (m) ->
    m.split('\r').join('')

  #-------------------------------------------------------------

  _find_sig_in_raw : (proof_text_check, raw) ->
    return space_normalize(raw).indexOf(space_normalize(proof_text_check)) >= 0

  #-------------------------------------------------------------

  _get_url_body: (opts, cb) ->
    ###
      cb(err, status, body) only replies with body if status is 200
    ###
    body = null
    opts.proxy = @proxy if @proxy?
    opts.ca = @ca if @ca?
    opts.timeout = constants.http_timeout unless opts.timeout?
    opts.headers or= {}
    opts.headers["User-Agent"] = user_agent
    await @libs.request opts, defer err, response, body
    rc = if err?
      if err.code is 'ETIMEDOUT' then               v_codes.TIMEOUT
      else                                          v_codes.HOST_UNREACHABLE
    else if (response.statusCode in [401,403]) then v_codes.PERMISSION_DENIED
    else if (response.statusCode is 200)       then v_codes.OK
    else if (response.statusCode >= 500)       then v_codes.HTTP_500
    else if (response.statusCode >= 400)       then v_codes.HTTP_400
    else if (response.statusCode >= 300)       then v_codes.HTTP_300
    else                                            v_codes.HTTP_OTHER
    cb err, rc, body

  #--------------------------------------------------------------

#==============================================================

exports.BaseScraper = BaseScraper

#==============================================================

exports.sncmp = sncmp = (a,b) ->
  if not a? or not b? then false
  else
    a = ("" + a).toLowerCase()
    b = ("" + b).toLowerCase()
    (a is b)

#================================================================================
