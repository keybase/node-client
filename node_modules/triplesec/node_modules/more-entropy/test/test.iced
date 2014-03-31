{Generator} = require '../lib/main.js'

g = new Generator()
g.generate 64, (vals) ->
  console.log vals.join ","
  process.exit 0