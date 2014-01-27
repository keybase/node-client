
request = require 'request'
cheerio = require 'cheerio'

#=====================================================================

exports.TwitterBot = class TwitterBot

  constructor : ({@username, @password}) ->

  load_page : (path, status = [200], cb) ->
    uri = [ "https://twitter.com" , path ].join "/"
    await request { uri, cookie_jar : true }, defer err, res, body
    if not err? and not((sc = res.statusCode) in status)
      err = new Error "HTTP status code #{sc}"
    cb err, body, res

  load_login_page : (cb) ->
    await @load_page "/login", null, defer err, body
    $ = cheerio.load body
    tok = (JSON.parse $("#init-data").val()).formAuthenticityToken
    console.log tok
    cb err

#=====================================================================

bot = new TwitterBot {}
await bot.load_login_page defer()
