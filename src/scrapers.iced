log = require './log'
request = require 'request'
cheerio = require 'cheerio'
{env} = require './env'
proofs = require 'keybase-proofs'
{E} = require './err'
{CHECK,BAD_X} = require './display'
colors = require 'colors'
proxyca = require './proxyca'
root_certs = require '../json/node_root_certs.json'
semver = require 'semver'

#==============================================================

_certs = null
my_request = (opts, cb) ->
  if semver.lt(process.version, "0.10.26")
    _certs = (v for k,v of root_certs) if not _certs?
    opts.ca = _certs unless opts.ca?
  request opts, cb

#==============================================================

class Base

  constructor : () ->
    @make_scraper()

  make_scraper : () ->
    klass = @get_scraper_klass()
    @_scraper = new klass { 
      libs : { cheerio, request : my_request, log }, 
      log_level : 'debug', 
      proxy : env().get_proxy() 
      ca : proxyca.get()?.data()
    }

  #-------------------

  single_occupancy : () -> false

  #-------------------

  scraper : () -> @_scraper

  #-------------------

  get_sub_id : () -> null

  #-------------------

  validate : (arg, cb) -> 
    await @_scraper.validate arg, defer err, rc
    cb err, rc

#==============================================================

class SocialNetwork extends Base

  format_msg : ({arg, ok}) -> [
    (if ok then CHECK else BAD_X) 
    ('"' + ((if ok then colors.green else colors.red) arg.username) + '"')
    "on"
    (@which() + ":")
    arg.human_url
  ]
  to_list_display : (arg) -> arg.username

  check_proof : (check_data_json) -> check_data_json?.name is @which()

#==============================================================

exports.Twitter = class Twitter extends SocialNetwork
  constructor : () ->
  get_scraper_klass : () -> proofs.TwitterScraper
  which : () -> "twitter"

#==============================================================

exports.Github = class Github extends SocialNetwork
  constructor : () ->
  get_scraper_klass : () -> proofs.GithubScraper
  which : () -> "github"

#==============================================================

exports.Dns = class Dns extends Base
  constructor : () ->
  get_scraper_klass : () -> proofs.DnsScraper
  get_sub_id : (o) -> o.domain.toLowerCase()
  to_list_display : (o) -> @get_sub_id(o)
  format_msg : ({arg, display, ok}) ->
    color = if ok then 'green' else 'red'
    return [
      (if ok then CHECK else BAD_X),
      "admin of the DNS zone for"
      colors[color](arg.domain)
    ]
  check_proof : (check_data_json) -> check_data_json.domain?

#==============================================================

exports.GenericWebSite = class GenericWebSite extends Base
  constructor : () ->
  get_scraper_klass : () -> proofs.GenericWebSiteScraper
  get_sub_id : (o) -> (x.toLowerCase() for x in [ o.protocol, o.hostname ]).join "//"
  to_list_display : (o) -> @get_sub_id o

  format_msg : ({arg, display, ok}) -> 
    color = if not(ok) then 'red'
    else if arg.protocol is 'http:' then 'yellow'
    else 'green'
    return [
      (if ok then CHECK else BAD_X),
      "admin of"
      colors[color](arg.hostname)
      "via"
      colors[color](arg.protocol.toUpperCase()),
      arg.human_url
    ]

  check_proof : (check_data_json) -> check_data_json.protocol? and check_data_json.hostname?

#==============================================================

exports.alloc = (type, cb) ->
  o = alloc_stub type
  if o?
    o.make_scraper()
  else
    err = new E.ScrapeError "cannot allocate scraper of type #{type}"
  cb err, o

#==============================================================

exports.alloc_stub = alloc_stub = (type) ->
  PT = proofs.constants.proof_types
  err = scraper = null
  klass = switch type
    when PT.twitter          then Twitter
    when PT.github           then Github
    when PT.generic_web_site then GenericWebSite
    when PT.dns              then Dns
    else null
  if klass then new klass {} 
  else null

#==============================================================
