{spawn, exec} = require 'child_process'
fs            = require 'fs'
path          = require 'path'

LIB = "lib/"

task 'build', 'build the whole jam', (cb) ->  
  console.log "Building"
  files = fs.readdirSync 'src'
  files = ('src/' + file for file in files when file.match(/\.iced$/))
  await clearLibJs defer()
  await runIced [ '-I', 'node', '-c', '-o', LIB ].concat(files), defer()
  await writeVersion defer()
  console.log "Done building."
  cb() if typeof cb is 'function'

runIced = (args, cb) ->
  proc =  spawn 'node_modules/.bin/iced', args
  proc.stderr.on 'data', (buffer) -> console.log buffer.toString()
  proc.stdout.on 'data', (buffer) -> console.log buffer.toString().trim()
  await proc.on 'exit', defer status 
  process.exit(1) if status != 0
  cb()

clearLibJs = (cb) ->
  files = fs.readdirSync 'lib'
  files = ("lib/#{file}" for file in files when file.match(/\.js$/))
  fs.unlinkSync f for f in files
  cb()

task 'test', "run the test suite", (cb) ->
  await runIced [ "test/all.iced"], defer()
  cb() if typeof cb is 'function'

task 'vtest', "run the test suite, w/ verbosity", (cb) ->
  await runIced [ "test/all.iced", '-d'], defer()
  cb() if typeof cb is 'function'

writeVersion = (cb) ->
  infile = "package.json"
  stem = "version.js"
  outfile = path.join LIB, stem
  await fs.readFile infile, defer err, data
  ok = false
  if err
    console.log "Error reading #{infile}: #{err}"
  else
    try
      obj = JSON.parse data
      v = obj.version
      code = "exports.version = \"#{v}\";"
      await fs.writeFile outfile, code, defer err
      if err
        console.log "Error writing #{outfile}: #{err}"
      else
        ok = true
    catch e
      console.log "JSON parse error: #{e}"
  cb ok
