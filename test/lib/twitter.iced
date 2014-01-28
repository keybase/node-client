
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
    headers = 
      "User-Agent" : "user-agent:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36"
    await request { uri, jar : true, form, method, headers }, defer err, res, body
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
    path = "/sessions"
    await @load_page { status : [302,200], path , form, method : "POST" }, defer err, body
    cb err

  #---------------------------------

  get_home : (cb) ->
    path = "/"
    await @load_page { path , method : "GET" }, defer err, body
    $ = cheerio.load body
    await @grab_auth_token $, defer err, @tok
    cb err

  #---------------------------------

  tweet : (txt, cb) ->
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
  await bot.get_home esc defer()
  await bot.tweet "this be the tweet 3003", esc defer()
  cb null

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



await test defer err
console.log err
