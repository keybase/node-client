
{Parser,parse} = require '../../lib/index'
{TmpKeyRing} = require '../../lib/keyring'

#======================================================================

gpg_output = """
tru::1:1392463756:1439900531:3:1:5
pub:u:2048:17:76D78F0500D026C4:1282220531:1439900531::u:::scESC:
fpr:::::::::85E38F69046B44C1EC9FB07B76D78F0500D026C4:
uid:u::::1344775710::CAACC8CE9116A0BE42E58C61602F127B194EF5A5::GPGTools Team <team@gpgtools.org>:
uid:u::::1344775710::8CACAFAD028BE38151D2361F9CD79CC81B4153B2::GPGTools Project Team (Official OpenPGP Key) <gpgtools-org@lists.gpgtools.org>:
uid:u::::1282220531::03B2DCE7652DBBB93DA77FFC4328F122656E20DD::GPGMail Project Team (Official OpenPGP Key) <gpgmail-devel@lists.gpgmail.org>:
uat:u::::1321476238::076E59FC200B10E38AEEA745AB6547AEE99FB9EE::1 5890:
sub:u:2048:16:07EAE49ADBCBE671:1282220531:1439900531:::::e:
pub:e:2048:1:78DCF9A45638F6F1:1324057408:1381019002::u:::esca:
fpr:::::::::5CB9294EDE703C2ED76B649478DCF9A45638F6F1:
uid:e::::1380932602::BAE797EBBD23C9257BC5C5274AE498263601FFFF::Max Krohn <max@okcupid.com>:
sub:e:2048:1:9B54F0B9FC576209:1324057408:1450287808:::::esa:
pub:e:2048:1:4437D388669EF5CF:1342348430:1381015753::u:::esca:
fpr:::::::::142B2FB6EC949AB9AAC6E2904437D388669EF5CF:
uid:e::::1380929353::759D5C7C38AD60551D46D2E6F34BA03640FE4379::Maxwell Krohn <themax@gmail.com>:
sub:e:2048:1:86AEC52166C49EC9:1342348430:1468578830:::::esa:
pub:u:4096:1:63847B4B83930F0C:1380929487:1507159887::u:::escaESCA:
fpr:::::::::4475293306243408FA5958DC63847B4B83930F0C:
uid:u::::1386987949::759D5C7C38AD60551D46D2E6F34BA03640FE4379::Maxwell Krohn <themax@gmail.com>:
uid:u::::1380929487::14BC0C35326061518657E0B8F71A23E0CA537034::Max Krohn <themax@gmail.com>:
sub:u:4096:1:2FE01C454348DA39:1380929487:1507159887:::::esa:
pub:u:4096:1:FBC07D6A97016CB3:1381159886:1507390286::u:::escaESCA:
fpr:::::::::94AA3A5BDBD40EA549CABAF9FBC07D6A97016CB3:
uid:u::::1381159886::CF5361B3D400B377CED49FD557B744E93FA344D4::Chris Coyne <chris@chriscoyne.com>:
sub:u:4096:1:D224413B1CFA6490:1381159886:1507390286:::::esa:
pub:-:4096:1:EBF01804BCF05F6B:1346326188:::-:::escaESCA:
fpr:::::::::428DF5D63EF07494BB455AC0EBF01804BCF05F6B:
uid:-::::1360530305::ED4AFBC98FD3B49AE8CA7733A27BE82FFFB5E53F::Filippo Valsorda <filippo.valsorda@gmail.com>:
uid:-::::1360528876::788372CBC7DDF24564AEA7138ABB09A648499E32::Filippo Valsorda <filosottile.wiki@gmail.com>:
sub:e:2048:1:50223425F149AA25:1360529005:1392065005:::::s:
sub:e:2048:1:3D1C752C0D83D9EC:1360529191:1392065191:::::e:
pub:e:4096:1:56A4286A3DD61E72:1232175770:1263711770::-:::sc:
fpr:::::::::ADBDA177656FD5228E34C45656A4286A3DD61E72:
uid:e::::1232175770::913D07A9BE150E31934E0BDD30E0E72BAA00972D::Tarsnap source code signing key (Colin Percival) <cperciva@tarsnap.com>:
pub:u:4096:1:47484E50656D16C7:1384876967:1511107367::u:::scESC:
fpr:::::::::222B85B0F90BE2D24CFEB93F47484E50656D16C7:
uid:u::::1384876967::5379B9706C5D468C86A572B07E28EBDB26BE0E97::Keybase.io Code Signing (v1) <code@keybase.io>:
sub:u:4096:1:5929664098F03378:1384876967:1511107367:::::e:
pub:-:4096:1:C9A2613970FB9C1A:1387730124:1703090124::-:::escaESCA:
fpr:::::::::F6E88E94B87E7F4739516D3CC9A2613970FB9C1A:
uid:-::::1387730124::55897318ED31ED923F78F39309C6A7B30712C5D3::keybase.io/taco3 (v0.0.1) <taco3@keybase.io>:
sub:-:2048:1:22A07D398AF7E83D:1387730124:1419266124:::::esa:
pub:-:4096:1:6FB0BE75C0B301AC:1388161792:1703521792::-:::escaESCA:
fpr:::::::::7BC8BF5CC032C179C2C82A486FB0BE75C0B301AC:
uid:-::::1388161792::FFFDF09966976366BE820498EEA957D65FE9C305::keybase.io/noob (v0.0.1) <noob@keybase.io>:
sub:-:2048:1:E35826CED986F0AC:1388161792:1419697792:::::esa:
pub:-:1024:1:C149654BD8A2C080:1389446345:1704806345::-:::escaESCA:
fpr:::::::::DDF4EDB21FC5F94F9EDFF2C2C149654BD8A2C080:
uid:-::::1389446345::E2B10048BC87972EF6D9CC80A9C59945CF521044::keybase.io/noob6 (v0.0.1) <noob6@keybase.io>:
sub:-:1024:1:DA18DF4A4C231AF1:1389446345:1420982345:::::esa:
pub:f:4096:1:199A25A57F9E8BFA:1390244586:1705604586::-:::scESC:
fpr:::::::::50356E55ADBC1310C156B7F5199A25A57F9E8BFA:
uid:f::::1390244586::5D4D8FC2FE2BA87FABB596E5E02E3DA9416F9F1B::Keybase.io Index Signing (v1) <index@keybase.io>:
sub:f:4096:1:2A934F99974F25D4:1390244586:1705604586:::::e:
pub:u:4096:1:6052B2AD31A6631C:1391639420:1706999420::u:::escaESCA:
fpr:::::::::8EFBE2E4DD56B35273634E8F6052B2AD31A6631C:
uid:u::::1391639420::0E83836893BE1130CC0CCF718A26FA19BCDC5866::keybase.io/max (v0.0.1) <max@keybase.io>:
sub:u:2048:1:980A3F0D01FE04DF:1391639420:1423175420:::::esa:
pub:-:4096:1:5B094948B11151F2:1392237184:1707597184::-:::escaESCA:
fpr:::::::::E0600318C622F735D82EDF3D5B094948B11151F2:
uid:-::::1392237184::5D9DB4E2334A1681D7F40E30DFAE61319BAA78A5::keybase.io/capndesign (v0.0.1) <capndesign@keybase.io>:
sub:-:2048:1:4BABF9BC0ABA323B:1392237184:1423773184:::::esa:
pub:u:1024:1:565DCCFB57308A88:1392463661:1518694061::u:::scESC:
fpr:::::::::EAF36B487D10F811A34EDC40565DCCFB57308A88:
uid:u::::1392463661::DF049F3B0441CA5D41B13407F3A6AFEF9E493238::Herbert Kitchener <herbert@kitchener.com>:
uat:u::::1392463749::4EA48152D3CC8001632378E58194F0EDDBB267D8::1 10942:
sub:u:1024:1:2A0CB1102B533C91:1392463661:1518694061:::::e:
"""

#======================================================================

exports.parse_1 = (T,cb) ->
  i = parse gpg_output
  T.assert i?, "index came back"
  q = "themax@gmail.com"
  results = i.lookup().email.get(q)
  T.equal results.length, 2, "the right number of records"
  for r,i in results
    found = false
    for u in r.userids()
      found = true if u.email is q
    T.waypoint("found #{q} in result #{i}")
    T.assert found, "found for result #{i}"
  cb()

#======================================================================

exports.parse_2 = (T,cb) ->
  p = new Parser gpg_output
  i = p.parse()
  T.assert i?, "index came back"
  T.equal p.warnings().warnings().length, 0, "no warnings"
  p = new Parser ("badstuff\n" + gpg_output + "\nbad:line\n")
  i = p.parse()
  T.assert i?, "index came back"
  w = p.warnings().warnings()
  T.equal w.length, 2, "found 2 warnings"
  T.equal w[0].indexOf("1: "), 0, "Found '1: ' error prefix"
  T.equal w[1].indexOf("69: "), 0, "Found '87: ' error prefix"
  cb()

#======================================================================

gpg_with_fingerprint2_output = """
tru::1:1393721309:1707777704:3:1:5
pub:-:4096:1:6052B2AD31A6631C:2014-02-05:2024-02-03::-:keybase.io/max (v0.0.1) <max@keybase.io>::escaESCA:
fpr:::::::::8EFBE2E4DD56B35273634E8F6052B2AD31A6631C:
sub:-:2048:1:980A3F0D01FE04DF:2014-02-05:2015-02-05:::::esa:
fpr:::::::::4AF88842F72A59565C669BDE980A3F0D01FE04DF:
pub:-:4096:1:BAD2382DE379088C:2014-03-01:2024-02-27::-:keybase.io/max2 <max2@keybase.io>::escaESCA:
fpr:::::::::741AE71745FE2A9FCE7FB5BCBAD2382DE379088C:
sub:-:4096:1:276556C8A2529039:2014-03-01:2024-02-27:::::esa:
fpr:::::::::D505C8C831C3DDF74813DDFF276556C8A2529039:
pub:-:4096:1:6ADC353FA59EAC16:2014-02-28:2024-02-26::-:keybase.io/max1 (v0.0.1) <max1@keybase.io>::escaESCA:
fpr:::::::::FA6DFC44C9426A3DEF8B72336ADC353FA59EAC16:
sub:-:2048:1:CF0E4A8E88CBB038:2014-02-28:2015-02-28:::::esa:
fpr:::::::::67D9D22291C4D64C0E038C32CF0E4A8E88CBB038:
pub:u:4096:1:C2A863B7D67F29AE:2014-03-02:2024-02-28::u:keybase.io/max2 <max2@keybase.io>::escaESCA:
fpr:::::::::A950C514D2EA4A9FB623C97FC2A863B7D67F29AE:
sub:u:4096:1:527C4EF645328914:2014-03-02:2024-02-28:::::esa:
fpr:::::::::AF8A6C125F1A20D89F0BC0A3527C4EF645328914:
pub:-:4096:1:CB963D072C21251A:2014-03-02:2024-02-28::-:keybase.io/max1 (v0.0.1) <max1@keybase.io>::escaESCA:
fpr:::::::::78E4953F9FF6661C60607AC8CB963D072C21251A:
sub:-:2048:1:19F02EE567F65B75:2014-03-02:2015-03-02:::::esa:
fpr:::::::::22B68606B648845584EABDFE19F02EE567F65B75:
pub:-:4096:1:63847B4B83930F0C:2013-10-04:2017-10-04::-:Maxwell Krohn <themax@gmail.com>::escaESCA:
fpr:::::::::4475293306243408FA5958DC63847B4B83930F0C:
uid:-::::2013-10-04::14BC0C35326061518657E0B8F71A23E0CA537034::Max Krohn <themax@gmail.com>:
sub:-:4096:1:2FE01C454348DA39:2013-10-04:2017-10-04:::::esa:
fpr:::::::::C4EE7BCBCE2F0953DCF9E8902FE01C454348DA39:
"""

#======================================================================

exports.parse_3 = (T, cb) ->
  p = new Parser gpg_with_fingerprint2_output
  i = p.parse()
  T.assert i?, "index came back"
  T.equal i.keys().length, 6, "got back 6 keys"
  v = i.lookup().email.get('max@keybase.io')
  T.equal v.length, 1, "got only 1 key back"
  T.equal v[0].fingerprint(), '8EFBE2E4DD56B35273634E8F6052B2AD31A6631C', "right primary fingerprint"
  T.equal v[0].key_id_64(), '6052B2AD31A6631C', "right primary key id 64"
  T.equal v[0].subkeys().length, 1, "got only one subkey"
  T.equal v[0].subkeys()[0].fingerprint(), '4AF88842F72A59565C669BDE980A3F0D01FE04DF', "right subkey fingerprint"
  T.equal v[0].subkeys()[0].key_id_64(), '980A3F0D01FE04DF', "right subkey fingerprint"
  cb()

#======================================================================

gpg_with_fingerprint_K_output = """
sec::1024:17:2FC3671F312AA0FD:1400185635::::::ES:::#:
fpr:::::::::FC60FD0920968905002D0B442FC3671F312AA0FD:
uid:::::1400185635::A268A2439BB76EAAD8FF5C1D049A57989CF46D1C::Max 94 <themax+942@gmail.com>:
ssb::2048:1:3E41DB0C88907077:1400185645::::::s::::
fpr:::::::::02ACD95A6D8C84FBC3216D923E41DB0C88907077:
ssb::2048:1:29F867D20E6CF5B6:1400185659::::::e::::
fpr:::::::::B7C68A881CD1C60A993248B729F867D20E6CF5B6:
"""

#======================================================================

exports.parse_4 = (T, cb) ->
  p = new Parser gpg_with_fingerprint_K_output
  i = p.parse()
  T.assert i?, "index came back"
  T.equal i.keys().length, 1, "got back 1 key"
  v = i.lookup().email.get('themax+942@gmail.com')
  T.equal v.length, 1, "got only 1 key back"
  T.equal v[0].fingerprint(), 'FC60FD0920968905002D0B442FC3671F312AA0FD', "right primary fingerprint"
  T.equal v[0].key_id_64(), '2FC3671F312AA0FD', "right primary key id 64"
  T.equal v[0].subkeys().length, 2, "got two subkeys"
  T.equal v[0].subkeys()[0].fingerprint(), '02ACD95A6D8C84FBC3216D923E41DB0C88907077', "right subkey fingerprint"
  T.equal v[0].subkeys()[0].key_id_64(), '3E41DB0C88907077', "right subkey fingerprint"
  T.equal v[0].subkeys()[1].fingerprint(), 'B7C68A881CD1C60A993248B729F867D20E6CF5B6', "right subkey fingerprint"
  T.equal v[0].subkeys()[1].key_id_64(), '29F867D20E6CF5B6', "right subkey fingerprint"
  cb()

#======================================================================
