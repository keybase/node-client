
{parse} = require '../../lib/userid'

#--------

exports.test_parse = (T,cb) ->
  test = "Hello Bird (fish) <cat@dog.jay>"
  components = parse test
  T.assert test, "parse succeeded"
  T.equal components.username, "Hello Bird", "username correct"
  T.equal components.comment, "fish", "comment is right"
  T.equal components.email, "cat@dog.jay", "email is right"
  cb()

#--------

exports.test_no_comment = (T,cb) ->
  T.assert (parse("Name Here <nocomment@gmail.com>"))?, "parse worked"
  T.assert (parse("Name Here () <nocomment@gmail.com>"))?, "parse worked, empty comment"
  cb()

#--------

exports.test_no_email = (T,cb) ->
  p = parse("Name Here (with comment)")
  T.assert p, "worked without an email"
  T.equal p.username, "Name Here", "name was right"
  T.equal p.comment, "with comment", "comment was right"
  T.assert not(p.email?), "username was null"
  p = parse("Name Here ()")
  T.assert p, "worked with an empty comment"
  T.equal p.comment, "", "got an empty"
  T.equal p.username, "Name Here", "name here"
  T.assert not(p.email?), "username was null"
  cb()

#--------

exports.test_failed_parse_1 = (T,cb) ->
  bad_uids = [
    "shit <shit> <shit> (stuff)"
    "Stuff Stuff <bad> (worse)"
    "<bad> (worse) Never going to Work"
    "Never Going to <work@gmail.com> (not worth it)"
    "<just an email>"
    "(just a comment)"
  ]
  for b,i in bad_uids
    T.assert not((parse(b))?), "bad UID #{i} failed"
  cb()

