
{getopt} = require '../../'
exports.test = (T,cb) ->
  flags = [ 'a', 'b', "alice", "bob", "fox=trot", "g", "gong" ]
  argv = [
    "-a",
    "--bob",
    "--charlie", "dog"
    "--dog=spot",
    "-e", "echo",
    "--fox=trot"
  ]
  out = getopt argv, { flags }
  T.equal out.get("a","alice"), true, "-a/--alice worked"
  T.equal out.get("b","bob"), true, "-b/--bob worked"
  T.equal out.get("c", "charlie"), "dog", "-c/--charlie worked"
  T.equal out.get("d", "dog"), "spot", "-d/--dog worked"
  T.equal out.get("e", "echo"), "echo", "-e/--echo worked"
  T.equal out.get("f", "fox=trot"), true, "-f/--fox=trot worked"
  T.equal out.get("g","gong"), null, "-g/--gong failed"

  cb()

