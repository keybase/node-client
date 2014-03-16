
log = require './log'
request = require './request'
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

exports.make = (type, cb) ->
  PT = proofs.constants.proof_types
  err = scraper = null
  klass = switch type
    when PT.twitter          then Twitter
    when PT.github           then Github
    when PT.generic_web_site then GenericWebSite
    else null
  if not klass
    err = new E.ScrapeError "cannot allocate scraper of type #{type}"
  else
    w = new klass {}
  cb err, w

#==============================================================
