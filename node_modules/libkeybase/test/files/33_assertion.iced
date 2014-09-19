
{URI,parse,Proof,ProofSet} = require('../../').assertion

expr = null

exports.parse_0 = (T,cb) ->
  expr = parse "reddit://a && twitter://bb"
  cb()

exports.match_0 = (T,cb) ->
  ps = new ProofSet [(new Proof { key : "reddit", value : "a" })]
  T.assert not expr.match_set(ps), "shouldn't match"
  cb()

exports.parse_1 = (T,cb) ->
  expr = parse """
    web://foo.io || (reddit://a && twitter://bbbbb && fingerprint://aabbcc)
  """
  T.equal expr.toString(), '(web://foo.io || ((reddit://a && twitter://bbbbb) && fingerprint://aabbcc))'
  cb()

exports.match_1 = (T,cb) ->
  ps = new ProofSet [(new Proof { key : "https", value : "foo.io" }) ]
  T.assert expr.match_set(ps), "first one matched"
  ps = new ProofSet [(new Proof { key : "https", value : "foob.io" }) ]
  T.assert not(expr.match_set(ps)), "second didn't"
  ps = new ProofSet [
    (new Proof { key : "reddit", value : "a" })
    (new Proof { key : "twitter", value : "bbbbb" })
    (new Proof { key : "fingerprint", value : "001122aabbcc" })
  ]
  T.assert expr.match_set(ps), "third one matched"
  ps = new ProofSet [
    (new Proof { key : "reddit", value : "a" })
    (new Proof { key : "fingerprint", value : "001122aabbcc" })
  ]
  T.assert not expr.match_set(ps), "fourth one didn't"
  ps = new ProofSet [
    (new Proof { key : "reddit", value : "a" })
    (new Proof { key : "twitter", value : "bbbbb" })
    (new Proof { key : "fingerprint", value : "aabbcc4" })
  ]
  T.assert not expr.match_set(ps), "fifth didn't"
  cb()

exports.parse_2 = (T,cb) ->
  expr = parse "http://foo.com"
  ps = new ProofSet [(new Proof { key : 'http', value : 'foo.com'})]
  T.assert expr.match_set(ps), "first one matched"
  ps = new ProofSet [(new Proof { key : 'https', value : 'foo.com'})]
  T.assert expr.match_set(ps), "second one matched"
  ps = new ProofSet [(new Proof { key : 'dns', value : 'foo.com'})]
  T.assert not expr.match_set(ps), "third didnt"
  cb()

exports.parse_bad_1 = (T,cb) ->
  bads = [
    "reddit"
    "reddit://"
    "reddit://aa ||"
    "reddit://aa &&"
    "reddit:// && ()"
    "fingerprint://aaXXxx"
    "dns://shoot"
    "http://nothing"
    "foo://bar"
    "keybase://ok || dns://fine.io || (twitter://still_good || bad://one)"
  ]
  for bad in bads
    try
      parse bad
      T.assert false, "#{bad}: shouldn't have parsed"
    catch error
      T.assert error?, "we got an error"
  cb()

exports.parse_URI = (T,cb) ->
  r = URI.parse { s : "max", strict : false }
  T.assert r?, "got something back without strict mode"
  try
    URI.parse { s : "max", strict : true }
    T.assert false, "should not have worked with strict mode"
  catch err
    T.assert err?, "error on strict mode without key"
  cb()

