
{colgrep} = require '../../lib/main'

exports.test1 = (T, cb) ->
  input = """
pub:u:2048:1:CC19461E16CD52C8:1388413669:1703773669::u:::scESC:
uid:u::::1388413669::4A1C93DDE1779B6BE90393F4394AD983EC785808::Brown Hat I (pw is 'a') <themax+browhat1@gmail.com>:
sub:u:2048:1:079F6793014A5F79:1388413669:1703773669:::::e:
pub:f:1024:1:5308C23E96D307BE:1387294526:1702654526::-:::escaESCA:
uid:f::::1387294526::9A7B91D6B62DC24454C408CB4D98210A31F4235F::keybase.io/taco1 (v0.0.1) <taco1@keybase.io>:
sub:f:1024:1:5F8664C8B707AD86:1387294526:1418830526:::::esa:
pub:-:1024:1:361D07D32CDF514E:1389274486:1704634486::-:::escaESCA:
uid:-::::1389274486::039EE0C3AD2BCAFEA038A768F4288963FDD7C1E6::keybase.io/taco19 (v0.0.1) <taco19@keybase.io>:
sub:-:1024:1:6F61BAE56CA1B67A:1389274486:1420810486:::::esa:
"""
  res = colgrep {
    patterns : {
      0 : /pub|sub/
      4 : /A.*7/
    },
    buffer : (new Buffer input, 'utf8')
    separator : /:/
  }
  T.equal res[0]?[4], '079F6793014A5F79', 'first row found'
  T.equal res[1]?[4], '6F61BAE56CA1B67A', '2nd row found'
  cb()