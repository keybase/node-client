
{address} = require '../../lib/main'


exports.check_good = (T, cb) ->
  a = "1PUr4cy6J7hi6GxQa2hX2iuXJkvZvCrKmW"
  [err,ret] = address.check a
  T.no_error err
  T.equal ret.version, 0
  cb()

exports.check_bad_address_1 = (T,cb) ->
  b = "1PUr4cy6J7hi6GxQa2hX2iuXJkvZvCrKmi"
  [err,ret] = address.check b
  T.assert err?, "an error"
  T.equal err.message, "Checksum mismatch"
  cb()

exports.check_bad_address_2 = (T,cb) ->
  b = "1PUr4cy6J7hi6GxQa2hX2iuXJkvZvCrKm$$$"
  [err,ret] = address.check b
  T.assert err?, "an error"
  T.equal err.message, "Value passed is not a valid BaseX string."
  cb()

exports.check_bad_coin_1 = (T,cb) ->
  # This is a litecoin address
  c = "LdoZadzUUFoazyDLEm3G73b9XKAd8hu8oc"
  [err,ret] = address.check c
  T.assert err?, "an error"
  T.equal err.message, "Bad version found: 48"
  cb()

exports.good_alt_coin_1 = (T,cb) ->
  # This is a litecoin address
  c = "LdoZadzUUFoazyDLEm3G73b9XKAd8hu8oc"
  [err,ret] = address.check c, { versions : [48] }
  T.no_error err
  T.equal ret.version, 48, "version was right"
  cb()
