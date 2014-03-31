fs            = require 'fs'
path          = require 'path'
iu            = require 'iced-utils'
{spawn}       = iu.spawn
{mkdir_p}     = iu.fs
colors        = require 'colors'

##=======================================================================

LIB = "lib/"
SRC = "src/"
BUILD = "build"
DIRMODE = 0o755

##=======================================================================

error = (e) ->
  console.log e.red
  process.exit -1
info = (e) -> console.log e.green

##=======================================================================

cbcall = (cb) -> cb() if typeof cb is 'function'

list = (dir, rxx, cb) ->
  await fs.readdir dir, defer err, files
  error "Error reading directory #{dir}: #{err}" if err?
  files = (path.join(dir,f) for f in files when f.match rxx)
  cb files
  
build = (cb) ->
  await mkdir_p LIB, DIRMODE, defer err
  await clear_lib_js defer()
  await list SRC, /\.(iced|coffee)$/, defer files
  await spawn [ '-I', 'none', '-c', '-o', LIB ].concat(files), defer()
  info "Done building."
  cb()

clear_lib_js = (cb) ->
  await list LIB, /\.js$/, defer files
  for f in files
    await fs.unlink f, defer err
    error "Error unlinking #{f}: #{err}" if err?
  cb()

get_version = (cb) ->
  file = path.join __dirname, "package.json"
  await fs.readFile file, defer err, dat
  error "Cannot read package.json: #{err}" if err?
  try
    p = JSON.parse dat
  catch e
    error "JSON parse error: #{e}" if e?
  cb p.version

##=======================================================================

task 'test', "run the test suite", (cb) ->
  await spawn [ "test/run.iced"], defer status
  process.exit(1) if status != 0
  cbcall cb

task 'btest', "run the test suite for the browser buffer (in node though)", (cb) ->
  await spawn [ "test/run.iced", '--browser'], defer status
  process.exit(1) if status != 0
  cbcall cb

task 'build', "build coffee into JS", (cb) ->
  await build defer()
  cbcall cb

##=======================================================================
