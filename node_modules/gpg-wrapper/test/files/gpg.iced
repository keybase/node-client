
{colgrep,GPG,set_gpg_cmd} = require '../../lib/main'

exports.test_assert_no_collision = (T,cb) ->
  obj = new GPG()
  await obj.run { args : [ "-k", "--with-colons" ] }, defer err, out
  T.no_error err
  out = colgrep {
    patterns : {
      0 : /[ps]ub/ 
    },
    buffer : out,
    separator : /:/
  }
  T.assert (out.length > 0), "need at least 1 key to make this work"
  key = out[0][4]
  await obj.assert_no_collision key, defer err, n
  T.no_error err
  T.equal n, 1, "we found exactly 1 key"
  cb()

exports.test_success = (T,cb) ->
  x = new GPG()
  await x.test defer err
  T.no_error err
  cb()

exports.test_failure = (T,cb) ->
  x = new GPG { cmd : "no_way_jose" }
  await x.test defer err
  T.assert err?, "failed to launch non-existent proc"
  cb()

 exports.test_failure_2 = (T,cb) ->
  set_gpg_cmd "blah_blah"
  x = new GPG { }
  await x.test defer err
  T.assert err?, "failed to launch non-existent proc"
  cb()

exports.test_success_2 = (T,cb) ->
  set_gpg_cmd "gpg"
  x = new GPG {}
  await x.test defer err
  T.no_error err, "and reset properly to standard gpg"
  cb()

