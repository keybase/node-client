
request = require 'request'
urlmod = require 'url'

#=====================================================================

exports.gist_api = gist_api = (d, gist, cb) ->
  form =
    description : "keybase proof"
    public : "true"
    files : 
      "keybase.md" :
        content : gist
  opts = 
    body : JSON.stringify form
    uri : "https://api.github.com/gists"
    method : "POST"
    json: true
    headers : 
      "User-Agent" : "keybase-node-client test (by @maxtaco)"
  if (t = d.personal_access_token)?
    opts.headers.Authorization = "token #{t}"
  else 
    opts.auth = d
  await request opts, defer err, res, body
  id = if err? then null else body.id
  cb err, id

#=====================================================================

test1 = (cb) ->
  tok = "e18260b20c759858614598ea7c725022a77da37f"
  headers =
  auth = 
    username : 'tacoplusplus'
    password : 'yoyoma22'
  headers = 
    "User-Agent" : "keybase-node-client test (by @maxtaco)"
    Authorization : "token #{tok}"
  form = 
    description : "keybase proof"
    public : true
    files : 
      "keybase.md" : 
        content : """
# test 1 2 3

```json
{
    "hello" : [1,2,3]

}
```
"""    
  body = JSON.stringify form
  uri = urlmod.parse("https://api.github.com/gists")
  opts = { uri, method : "POST", json : true, headers, body }
  console.log opts
  await request opts, defer err, res, body
  console.log res
  console.log err
  console.log body
  cb()

#=====================================================================

test2 = (cb) ->
  await gist_api { 
    personal_access_token : "e18260b20c759858614598ea7c725022a77da37f",
  }, "# Yo Peeps\n\n## Here is the gist", defer err, id
  console.log err
  console.log id

# await test2 defer()


