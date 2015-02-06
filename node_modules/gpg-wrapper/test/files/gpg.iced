
{pinentry_init,get_gpg_cmd,find_and_set_cmd,colgrep,GPG,set_gpg_cmd} = require '../../lib/main'

exports.pinentry_init = (T,cb) ->
  await pinentry_init defer err, out
  T.no_error err
  cb()

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


# Test will only work if you have both gpg and gpg2 installed
exports.test_find = (T,cb) ->
  await find_and_set_cmd null, defer err, version, cmd
  T.no_error err
  T.assert version?, "version came back"
  T.equal cmd, "gpg2", "should find gpg2 by default"
  T.equal get_gpg_cmd(), "gpg2", "should update global preferences"
  await find_and_set_cmd "gpg", defer err, version, cmd
  T.no_error err
  T.assert version?, "version came back"
  T.equal cmd, "gpg", "should find gpg if we asked"
  T.equal get_gpg_cmd(), "gpg", "should update global preferences"
  cb()
