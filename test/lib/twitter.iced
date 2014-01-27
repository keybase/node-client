
request = require 'request'
cheerio = require 'cheerio'
{katch} = require('iced-utils').util
{make_esc} = require('iced-error')
util = require 'util'

#=====================================================================

exports.TwitterBot = class TwitterBot

  constructor : ({@username, @password}) ->
    @jar = request.jar()

  #---------------------------------

  load_page : ({path, status, form, method }, cb) ->
    status or= [200]
    uri = [ "https://twitter.com" , path ].join ""
    form.authenticity_token = @tok if form? and @tok?
    await request { uri, jar : true, form, method }, defer err, res, body
    console.log util.inspect res, { depth : null }
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
    await @load_page {path : "/login" }, esc defer body
    $ = cheerio.load body
    await @grab_auth_token $, esc defer @tok
    cb null

  #---------------------------------

  post_login : (cb) ->
    form =
      'session[username_or_email]' : @username
      'session[password]' : @password
    uri = "/session"
    await @load_page { uri, form, method : "POST" }, defer err, body
    $ = cheerio.load body
    await @grab_auth_token $, defer err, @tok
    cb err

  #---------------------------------

  tweet : (txt, cb) ->
    console.log "shit"
    await @load_page { 
      path : "/i/tweet/create", 
      method : "POST", 
      form : {status : txt, place_id : "" },
      }, defer err, body
    cb err

#=====================================================================

test = (cb) ->
  esc = make_esc cb, "tesT"
  bot = new TwitterBot { username : "tacovontaco", password : "yoyoma" }
  await bot.load_login_page esc defer()
  await bot.post_login esc defer()
  await bot.tweet "this be the tweet 22", esc defer()

#=====================================================================

d = { "username" : "tacovontaco", "password" : "yoyoma", 
"consumer_key" : "5mWTsSzItVHdxaJfYi00Rw", 
"consumer_secret" : "Hzz6fqwxrbAkKcPKjvtnqU1FN0OYi7gu93dS0gNbQ", 
token : "2209163989-lTgnNUDINbH1ijvSyvO62CuMzyRCi3R6uOIfcHN", 
token_secret : "gtskJSncqLQ7r9bXNnFcanfp1liW687KvYmbr30FLKheC" }
tweet = (cb) ->
  await request.post {
    url : "https://api.twitter.com/1.1/statuses/update.json",
    form : {
      status : "this is the new way"
    }
    oauth : d
  }, defer err, res, body
  console.log err
  console.log body



await tweet defer err
console.log err
