
{Leaf,Triple} = require('../..').merkle.leaf

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
  raws = [
    [ 2, null, [10, "aabb", "ee" ] ],
    [ 2, [10, "aaa", "bbb" ] ],
    [ 2, [10, "aa", "bbb" ] ],
    [ 2, [10, "aaa", "bb" ] ],
    [ 2, [ "a", "aaa", "bb" ] ],
  ]
  for raw,i  in raws
    [err,leaf] = Leaf.parse raw
    T.assert err?, "parse error on object #{i}"
  cb()

#====================================================

