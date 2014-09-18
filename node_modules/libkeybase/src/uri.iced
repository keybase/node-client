
"""
#
#  Key-identier URIs, like:
#
#    kbk://max@/aabbccee20/iphone+2
#    kbk://max@keybase.io/aabbccee20/iphone+2   [equivalent to the above]
#    kbk://max;fingerprint=8EFBE2E4DD56B35273634E8F6052B2AD31A6631C@/aabbccee20/iphone+3 [pinning a key]
#
#  We're going off of URI-scheme as in this page:
#     - official: http://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
#     - conventional: http://en.wikipedia.org/wiki/URI_scheme
#
#  Within those schemes, that for SSH looks sort of like the above:
#     - https://tools.ietf.org/html/draft-ietf-secsh-scp-sftp-ssh-uri-04
#
#  In the above examples, 'aabbccee20' is an App ID.
#
"""

#==================================================================================

exports.URI = class URI

  #--------------------------

  constructor : ({@username, @fingerprint, @app_id, @device_id, @host, @port}) ->

  #--------------------------

  format : ({full}) ->
    parts = [ "kbk:/" ]

    throw new Error "need username" unless @username

    authority = @username
    authority += ";fingerprint=#{@fingerprint}" if @fingerprint?
    authority += "@"
    host = @host or (if full then "keybase.io" else null)
    if host? then authority += "#{host}"
    if @port? and @port isnt 443 then authority += ":#{@port}"
    parts.push authority

    app_id = @app_id or 0
    parts.push app_id
    parts.push @device_id if @device_id

    return parts.join("/").toLowerCase()

  #--------------------------

  @parse : (s) ->
    obj = {}
    parts = s.split '/'
    if parts.length < 3 or parts[0] isnt 'kbk:' or parts[1].length isnt 0
      throw new Error "#{s}: can't parse keybase URI that doesn't start with kbk://"
    authority = parts[2].split "@"
    if authority.length isnt 2
      throw new Error "#{s}: 'authority' section must be username@[host]"
    userinfo = authority[0].split ";"
    username = userinfo[0]
    unless username? and username.length
      throw new Error "#{s}: 'username' section is required"
    obj.username = username
    for ui in userinfo[1...]
      [k,v] = ui.split("=")
      if k is "fingerprint"
        obj.fingerprint = v
      else
        throw new Error "#{s}: 'fingerprint=' is the only userinfo now allowed"
    if authority[1].length > 0
      host = authority[1].split ':'
      if host.length > 2
        throw new Error "#{s}: [hostname[:port]] did not parse"
      else
        obj.host = host[0]
        if host.length is 2
          port = parseInt(host[1], 10)
          throw new Error "#{s}: bad port given" if isNaN(port)
          obj.port = port

    # The remaining hierchical parts
    if parts.length > 3
      hier = parts[3...]
      obj.app_id = hier[0]
      obj.device_id = hier[1...].join('/')

    obj.app_id or= 0

    return new URI obj

  #--------------------------

  eq : (uri2) -> (@format { full : true }) is (uri2.format { full : true })

#==================================================================================

