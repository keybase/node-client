mp = require 'msgpack2'
{Packer}  = require '../src/pack'

obj = { "boo" : "dawg", "yo" : "bbbbbbB", "bizzle" : null, "yes" : true, "one" : 1 }

class Timer
  constructor : ->
    @_start = (new Date()).getTime()
  stop : ->
    now = (new Date()).getTime()
    now - @_start

iters = 1000000

mpt = new Timer()
for i in [0...iters]
  mp.pack obj
console.log "iters #{iters}: native msgpack2: #{mpt.stop()}"

ppt = new Timer()
for i in [0...iters]
  packer = new Packer()
  packer.p obj
console.log "iters #{iters}: purepack:  #{ppt.stop()}"
