
{Leaf,Triple} = require('../..').merkle.leaf
C = require('../..').constants

#====================================================

exports.test_v1 = (T,cb) ->
  raw = [ 2, "aabb", "ccdd" ]
  [err,leaf] = Leaf.parse raw
  T.no_error err
  T.equal leaf.get_public().to_json(), raw, "the right leaf value came back"
  cb()

#====================================================

exports.test_v2_1 = (T,cb) ->
  raw = [ 2, [ 1, "aabb", "ccdd" ], [ 2, "eeff", "0011" ] ]
  [err,leaf] = Leaf.parse raw
  T.no_error err
  T.equal leaf.get_public().to_json(), raw[1], "the right public leaf value came back"
  T.equal leaf.get_semiprivate().to_json(), raw[2], "the right semiprivate leaf value came back"
  cb()

#====================================================

exports.test_v2_2 = (T,cb) ->
  raw = [ 2, [ 1, "aabb", "ccdd" ] ]
  [err,leaf] = Leaf.parse raw
  T.no_error err
  T.equal leaf.get_public().to_json(), raw[1], "the right public leaf value came back"
  T.assert not(leaf.get_semiprivate()?), "the right semiprivate leaf value came back"
  cb()

#====================================================


exports.test_v2_3 = (T,cb) ->
  bads = [
    [ ],
    [ "foo", null ],
    [ 3, null ],
    [ 2, [10, "aaa", "bbb" ] ],
    [ 2, [10, "aa", "bbb" ] ],
    [ 2, [10, "aaa", "bb" ] ],
    [ 2, [ "a", "aaa" ] ],
    [ 2, [10, "aa", "bb"], null, "a"],
    [ 2, [10, "aa", "bb"], [], "a"]
    [ 2, [1 ]  ],
    [ 2  ],
  ]
  for bad,i in bads
    [err,leaf] = Leaf.parse bad
    T.assert err?, "parse error on object #{i}"

  goods = [ 
    [ 2, [1, "", "" ]  ],
    [ 2, [], [], "aa" ]
    [ 2, null, null, "aa" ]
    [ 2, [], null, "aa" ]
    [ 2, null, [], "aa" ]
  ]
  for good, i in goods
    [err,leaf] = Leaf.parse good
    T.no_error err

  cb()

#====================================================

# test that beyond slots 1,2,3, it's open-ended
exports.test_v2_4 = (T,cb) ->
  raw = [ 2, [ 1, "aabb", "ccdd", "4455", "other", "stuff", [ 1,2,3 ], { a: 3} ], [ 2, "eeff", "0011" ] ]
  [err,leaf] = Leaf.parse raw
  T.no_error err
  T.equal leaf.get_public().to_json(), raw[1][0...3], "the right public leaf value came back"
  T.equal leaf.get_semiprivate().to_json(), raw[2], "the right semiprivate leaf value came back"
  cb()

#====================================================

# test that beyond slots 1,2,3, it's open-ended
exports.test_v2_5 = (T,cb) ->
  raw = [ 2,
          [ 1, "aabb", "ccdd", "4455", "other", "stuff", [ 1,2,3 ], { a: 3} ],
          [ 2, "eeff", "0011" ],
          "112233"
        ]
  [err,leaf] = Leaf.parse raw
  T.no_error err
  T.equal leaf.get_public().to_json(), raw[1][0...3], "the right public leaf value came back"
  T.equal leaf.get_semiprivate().to_json(), raw[2], "the right semiprivate leaf value came back"
  T.equal leaf.get_eldest_kid(), raw[3], "the right eldest kid leaf value came back"

  [err,leaf] = Leaf.parse leaf.to_json()
  T.no_error err
  T.equal leaf.get_eldest_kid(), raw[3], "full parse roundtrip"
  cb()

#====================================================

exports.test_v2_6 = (T,cb) ->
  raw = [ 2, null, null, "112233"]
  [err,leaf] = Leaf.parse raw
  T.no_error err
  [err,leaf] = Leaf.parse JSON.parse leaf.to_string()
  T.no_error err
  T.equal leaf.get_eldest_kid(), raw[3], "full parse roundtrip"
  cb()

#====================================================

exports.test_seqno_assertion = (T,cb) ->
  raw = [2, [ 10, "aa", "bb" ], [ 11, "cc", "dd" ], "ffee"]
  rows = [
    {seqno_type : C.seqno_types.PUBLIC, seqno : 10 },
    {seqno_type : C.seqno_types.SEMIPRIVATE, seqno : 11 },
  ]
  [err, leaf] = Leaf.parse raw
  T.no_error err
  assert = leaf.seqno_assertion()
  ok = assert(rows)
  T.assert ok, "assertion came back true"

  rows = [{ seqno_type : 10000, seqno : 10 } ]
  ok = assert(rows)
  T.assert not(ok), "bad seqno type"

  rows = [
    {seqno_type : C.seqno_types.PUBLIC, seqno : 10 },
  ]
  ok = assert(rows)
  T.assert not(ok), "missing semiprivate"

  rows = [
    {seqno_type : C.seqno_types.SEMIPRIVATE, seqno : 11 },
  ]
  ok = assert(rows)
  T.assert not(ok), "missing semiprivate"

  raw = [ 2, [10, "aa", "bb" ] ]
  rows = [
    {seqno_type : C.seqno_types.PUBLIC, seqno : 10 }
  ]
  [err, leaf] = Leaf.parse raw
  T.no_error err
  assert = leaf.seqno_assertion()
  ok = assert(rows)
  T.assert ok, "assertion came back true no semiprivate chain"

  raw = [ 2, null, [11, "cc", "dd" ] ]
  rows = [
    {seqno_type : C.seqno_types.SEMIPRIVATE, seqno : 11 }
  ]
  [err, leaf] = Leaf.parse raw
  T.no_error err
  assert = leaf.seqno_assertion()
  ok = assert(rows)
  T.assert ok, "assertion came back true no public chain"
  cb()



#====================================================

