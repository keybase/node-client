
log = require './log'
request = require 'request'
cheerio = require 'cheerio'
{env} = require './env'
proofs = require 'keybase-proofs'
{E} = require './err'
{CHECK,BAD_X} = require './display'
colors = require 'colors'

#==============================================================

class Base

  constructor : () ->
    @make_scraper()

  make_scraper : () ->
    klass = @get_scraper_klass()
    @_scraper = new klass { 
      libs : { cheerio, request, log }, 
      log_level : 'debug', 
      proxy : env().get_proxy() 
      ca : proxyca.get()?.data()
    }

  #-------------------

  scraper : () -> @_scraper

  #-------------------

  get_sub_id : () -> null

  #-------------------

  validate : (arg, cb) -> 
    await @_scraper.validate arg, defer rc
    ok = (rc is proofs.constants.v_codes.OK)
    msg = @format { arg, ok }
    cb rc, msg

#==============================================================

class SocialNetwork extends Base

  format : ({arg, ok}) -> [
    (if ok then CHECK else BAD_X) 
    ('"' + ((if ok then colors.green else colors.red) arg.username) + '"')
    "on"
    (@which() + ":")
    arg.human_url
  ]
  to_list_display : (arg) -> arg.username

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

exports.GenericWebSite = class GenericWebSite extends Base
  constructor : () ->
  get_scraper_klass : () -> proofs.GenericWebSiteScraper
  get_sub_id : (o) -> (x.toLowerCase() for x in [ o.protocol, o.hostname ]).join "//"
  to_list_display : (o) -> @get_sub_id o

  format : ({arg, display, ok}) -> 
    color = if not(ok) then 'red'
    else if arg.protocol is 'http' then 'yellow'
    else 'green'
    return [
      (if ok then CHECK else BAD_X),
      colors[color](arg.hostname + " via " + arg.protocol.toUpperCase()),
      arg.human_url
    ]

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
    else null
  if klass then new klass {} 
  else null

#==============================================================
