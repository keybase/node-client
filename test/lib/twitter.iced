
request = require 'request'
cheerio = require 'cheerio'
{katch} = require('iced-utils').util
{make_esc} = require('iced-error')

#=====================================================================

exports.TwitterBot = class TwitterBot

  constructor : ({@username, @password}) ->

  #---------------------------------

  load_page : (path, status = [200], cb) ->
    uri = [ "https://twitter.com" , path ].join "/"
    await request { uri, cookie_jar : true }, defer err, res, body
    if not err? and not((sc = res.statusCode) in status)
      err = new Error "HTTP status code #{sc}"
    cb err, body, res

  #---------------------------------

  grab_auth_token : ($, cb) ->
    err = null
    if not (raw = $("#init-data").val())? or raw.length is 0
      err = new Error "No #init-data form data found"
    else 
      [err, json] = katch () -> JSON.parse(raw)
    if not err? and not (ret = json.formAuthenticityToken)?
      err = new Error "init-data didn't have a 'formAuthenticityToken'"
    cb err, ret

  #---------------------------------

  load_login_page : (cb) ->
    esc = make_esc cb, "load_log_page"
    await @load_page "/login", null, esc defer body
    $ = cheerio.load body
    await @grab_auth_token $, esc defer tok
    console.log tok
    cb null

#=====================================================================

bot = new TwitterBot {}
await bot.load_login_page defer()
