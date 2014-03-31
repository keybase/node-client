
{E,GPG} = require '../../lib/main'

exports.test_error_1 = (T,cb) ->
  gpg = new GPG
  await gpg.run { args : [ "-k", "-e" ], quiet : 'true' }, defer err
  T.assert err?, "got an error back"
  T.assert (err instanceof E.GpgError), "of the right instance"
  T.equal err.stderr.toString('utf8'), "gpg: conflicting commands\n", "got an error in our Error"
  cb()