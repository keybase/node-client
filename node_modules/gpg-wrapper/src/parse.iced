{E} = require './err'
{GPG} = require './gpg'
util = require 'util'

#=======================================================================


strip = (x) -> if (m = x.match(/^\s*(.*)$/)) then m[1] else x

class Packet
  constructor : ( {@type, @options } ) -> @_subfields = []
  add_subfield : (f) -> @_subfields.push f
  subfields : () -> @_subfields

class Message
  constructor : (@_packets) ->
  packets : () -> @_packets

#=======================================================================

#
# Parse GPG messages using `gpg --list-packets`
#
exports.Parser = class Parser

  constructor : (@pgp_output) ->

  run : () ->
    @preprocess()
    new Message @parse_packets()

  preprocess : () -> @_lines = (line for line in @pgp_output.split(/\r?\n/) when line.match /\S/)
  parse_packets : () -> (@parse_packet() until @eof())
  peek : () -> @_lines[0]
  get : () -> @_lines.shift()
  eof : () -> @_lines.length is 0

  parse_packet : () ->
    rxx = /^:([a-zA-Z0-9_ -]+) packet:( (.*))?$/ 
    first = @get()
    unless (m = first.match rxx)
      throw new E.ParseError "expected ':literal data packet:' style header; got #{first}"
    packet = new Packet { type : m[1], options : m[3] }
    until (@eof() or @peek()[0] is ':')
      packet.add_subfield strip(@get())
    return packet

#=======================================================================

exports.parse = parse = ({gpg, message }, cb) ->
  gpg or= new GPG 
  out = null
  await gpg.run { args : [ "--list-packets"], stdin : message }, defer err, buf
  unless err?
    try
      out = (new Parser buf.toString('utf8')).run()
    catch e
      err = e
  cb err, out
      
#=======================================================================

