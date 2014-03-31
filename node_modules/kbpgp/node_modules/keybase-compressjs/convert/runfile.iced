
fs = require 'fs'
{make_esc} = require 'iced-error'
{exec} = require 'child_process'

class Runner

  constructor : (argv) ->
    @infile = argv[0]
    @outfile = argv[1]

  read : (cb) ->
    await fs.readFile @infile, defer err,  data
    unless err?
      rxx = /^(?:\s|\n)*(\/\*(?:.|\n)*?\*\/)?(?:\s|\n)*(if \(typeof define.*?\n)?((?:.|\n)*)$/
      m = data.toString('utf8').match(rxx)
      @indata = { comment : m[1], define : m[2], body : m[3] }
    cb null

  write_tmp : (cb) ->
    data = "var define = require('./define');\n" + @indata.body
    @tmp = "tmp.js"
    await fs.writeFile @tmp, data, defer err
    cb err

  run_node : (cb) ->
    cmd = "node ./#{@tmp}"
    console.log cmd
    await exec cmd, defer err, stdout, stderr
    @outdata = { comment : @indata.comment or '', body : stdout }
    cb err

  write_final : (cb) ->
    await fs.writeFile @outfile, (@outdata.comment + "\n" + @outdata.body), defer err
    cb err

  run : (cb) ->
    esc = make_esc cb, "run"
    await @read esc defer()
    await @write_tmp esc defer()
    await @run_node esc defer()
    await @write_final esc defer()
    cb null

runner = new Runner process.argv[2...]
await runner.run defer err
if err?
  console.log err
  process.exit 2
else
  process.exit 0
