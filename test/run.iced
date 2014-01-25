
argv = require('optimist').
   alias('c','config').
   describe('c', 'the config file to use (default: ~/.node_client_test.conf').
   argv

config = require('./lib/config')

await config.init { file : argv.c }, defer err
process.exit(-2) if err?
wl = if argv._.length > 0 then argv._ else null
require('iced-test').run { mainfile : __filename, whitelist : wl, files_dir : "files" }
