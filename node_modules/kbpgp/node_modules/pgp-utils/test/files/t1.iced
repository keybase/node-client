
{armor,util} = require '../../lib/main'

strip = (msg) -> (msg.split /\s+/).join('')

#---------------------

exports.encode_decode = (T,cb) ->
  type = "STUFF"
  data = util.bufferify "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  C = 
    header :
      version : "v1.2.3"
      comment : "hello friends"
  v = armor.encode C, type, data

  decode = (v) ->
    [err,msg] = armor.decode v
    T.no_error err
    T.equal msg.body.toString('utf8'), data.toString('utf8'), "bodies are equal"
    T.equal msg.comment, C.header.comment
    T.equal msg.version, C.header.version
    T.equal strip(msg.payload), msg.body.toString('base64')

  decode(v)
  T.waypoint "Simple encode/decode test"

  # Introduce a space in between the headers and the body
  parts = v.split /\n\n/ 
  v2 = parts[0] + "\n \n" + parts[1]

  decode(v2)
  T.waypoint "Decode test with a space in the separator"

  v3 = parts[0] + "\n \t\t   \t\n" + parts[1]
  decode(v3)
  T.waypoint "Decode test with space junk in the separator"

  # Introduce a newline and a space after the checksum
  i = v.indexOf("\n-----END PGP")
  v4 = v[0...i] + " \n" + v[i...]
  decode(v4)
  T.waypoint "Decode test with junk after checksum"

  cb()

#---------------------
