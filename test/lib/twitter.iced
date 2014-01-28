
request = require 'request'
cheerio = require 'cheerio'
{a_json_parse,katch} = require('iced-utils').util
{make_esc} = require('iced-error')
util = require 'util'

#=====================================================================

make_body = (d) ->
  pairs = for k,v of d
    [ encodeURIComponent(k), encodeURIComponent(v)].join '='
  pairs.join '&'

#=====================================================================

exports.TwitterBot = class TwitterBot

  constructor : ({@username, @password}) ->
    @jar = request.jar()

  #---------------------------------

  load_page : ({path, status, form, method }, cb) ->
    status or= [200]
    uri = [ "https://twitter.com" , path ].join ""
    body = null
    if form?
      form.authenticity_token = @tok if form? and @tok?
      body = make_body form
      body += "&authenticity_token=#{@tok}" if @tok
    console.log body
    headers = 
      "User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36"
      "referer" : "https://twitter.com/login"
    await request { uri, jar : true, body, method, headers }, defer err, res, body
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
      'redirect_after_login' : ''
      'remember_me' : 1
      'scribe_log' : ""
    path = "/sessions"
    console.log "fuuuuuck"
    console.log form
    await @load_page { status : [302,200], path , form, method : "POST" }, defer err, body, res
    console.log body
    console.log res
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
    esc = make_esc cb, "TwitterBot::tweet"
    await @load_page { 
      path : "/i/tweet/create", 
      method : "POST", 
      form : {status : txt, place_id : "" },
      }, esc defer body
    await a_json_parse body, esc defer json
    cb err, json.tweet_id

  #---------------------------------

  run : (txt, cb) ->
    esc = make_esc cb, "TwitterBot:run"
    await @load_login_page esc defer()
    await @post_login esc defer()
    await @get_home esc defer()
    await @tweet txt, esc defer tweet_id
    cb null, tweet_id

#=====================================================================

exports.tweet_scrape = tweet_scrape = ({username,password}, txt, cb) ->
  bot = new TwitterBot { username, password }
  await bot.run txt, defer err, tweet_id
  cb err, tweet_id

#=====================================================================

d = { "username" : "tacovontaco", "password" : "yoyoma", 
"consumer_key" : "5mWTsSzItVHdxaJfYi00Rw", 
"consumer_secret" : "Hzz6fqwxrbAkKcPKjvtnqU1FN0OYi7gu93dS0gNbQ", 
token : "2209163989-lTgnNUDINbH1ijvSyvO62CuMzyRCi3R6uOIfcHN", 
token_secret : "gtskJSncqLQ7r9bXNnFcanfp1liW687KvYmbr30FLKheC" }

test = (cb) ->
  await tweet_scrape d, process.argv[2], defer err
  cb err

#=====================================================================

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
