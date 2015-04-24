
{format_pgp_fingerprint_2} = require('../../').util

exports.test_fingerprint_1 = (T, cb) ->
  buf = new Buffer [30...50]
  fp = format_pgp_fingerprint_2 buf, { space : 'X' }
  T.equal fp, "1E1FX2021X2223X2425X2627XX2829X2A2BX2C2DX2E2FX3031", "formatted fingerprint was good"
  cb()
