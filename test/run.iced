
itest = require 'iced-test'
config = require('./lib/config')
{users} = require './lib/user'

#=========================

argv = require('optimist').
   alias('c','config').
   alias('d', 'debug').
   boolean('d').
   describe('d', 'debug mode').
   describe('c', 'the config file to use (default: ~/.node_client_test.conf').
   argv

#=========================

class MyRunner extends itest.ServerRunner

  finish : (cb) ->
    return cb true
    await users().cleanup defer()
    cb true

#=========================

await config.init { file : argv.c, debug : argv.d }, defer err
process.exit(-2) if err?
wl = if argv._.length > 0 then argv._ else null
require('iced-test').run { mainfile : __filename, whitelist : wl, files_dir : "files", klass : MyRunner }

#=========================
