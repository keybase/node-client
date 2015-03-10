
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
