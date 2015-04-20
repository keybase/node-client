{set_default_quiet,ExecEngine,set_default_engine,SpawnEngine,BufferOutStream,BufferInStream,run} = require '../../lib/main'
path = require 'path'
exports.skip = true if (process.platform is 'win32')

exports.init = (T,cb) ->
  set_default_engine SpawnEngine
  set_default_quiet false
  cb()

run_n = (n,T,cb) ->
  msg = "here is the message to filter through"
  other_fds = {}
  ns = "" + n
  other_fds[ns] = new BufferOutStream()
  name = process.execPath
  helper = path.join __dirname, "write_to_fd_n.js"
  await run { name, other_fds , args : [ helper, ns, msg ] }, defer err
  T.no_error err, "it worked without an error"
  T.equal other_fds[ns].data().toString('utf8'), msg, "got back the right data"
  cb()

exports.run_3 = (T,cb) -> run_n 3, T, cb
exports.run_8 = (T,cb) -> run_n 8, T, cb
