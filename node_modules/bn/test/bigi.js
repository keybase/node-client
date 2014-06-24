// Tests taken/merged from BN.js
//
// Copyright Fedor Indutny, 2014.
// https://github.com/indutny/bn.js/blob/master/test/bn-test.js

var assert = require('assert')
var BigInteger = require('../').BigInteger

describe('BigInteger', function () {
  it('should work without new', function() {
    var bi = BigInteger('12345')
    assert.equal(bi.toString(10), '12345')
  })

  it('should work with String input', function () {
    assert.equal(new BigInteger('12345').toString(16), '3039')
    assert.equal(new BigInteger('29048849665247').toString(16), '1a6b765d8cdf')
    assert.equal(new BigInteger('-29048849665247').toString(16), '-1a6b765d8cdf')
    assert.equal(new BigInteger('1A6B765D8CDF', 16).toString(16), '1a6b765d8cdf')
    assert.equal(new BigInteger('FF', 16).toString(), '255')
    assert.equal(new BigInteger('1A6B765D8CDF', 16).toString(), '29048849665247')
    assert.equal(new BigInteger('a89c e5af8724 c0a23e0e 0ff77500', 16).toString(16), 'a89ce5af8724c0a23e0e0ff77500')
    assert.equal(new BigInteger('123456789abcdef123456789abcdef123456789abcdef', 16).toString(16), '123456789abcdef123456789abcdef123456789abcdef')
    assert.equal(new BigInteger('10654321').toString(), '10654321')
    assert.equal(new BigInteger('10000000000000000').toString(10), '10000000000000000')
  })

  it('should import/export twos complement big endian', function () {
    assert.equal(new BigInteger([1, 2, 3], 256).toString(16), '10203')
    assert.equal(new BigInteger([1, 2, 3, 4], 256).toString(16), '1020304')
    assert.equal(new BigInteger([1, 2, 3, 4, 5], 256).toString(16), '102030405')
    assert.equal(new BigInteger([1, 2, 3, 4, 5, 6, 7, 8], 256).toString(16), '102030405060708')
    assert.equal(new BigInteger([1, 2, 3, 4], 256).toByteArray().join(','), '1,2,3,4')
    assert.equal(new BigInteger([1, 2, 3, 4, 5, 6, 7, 8], 256).toByteArray().join(','), '1,2,3,4,5,6,7,8')
  })

  it('should return proper bitLength', function () {
    assert.equal(new BigInteger('0').bitLength(), 0)
    assert.equal(new BigInteger('1', 16).bitLength(), 1)
    assert.equal(new BigInteger('2', 16).bitLength(), 2)
    assert.equal(new BigInteger('3', 16).bitLength(), 2)
    assert.equal(new BigInteger('4', 16).bitLength(), 3)
    assert.equal(new BigInteger('8', 16).bitLength(), 4)
    assert.equal(new BigInteger('10', 16).bitLength(), 5)
    assert.equal(new BigInteger('100', 16).bitLength(), 9)
    assert.equal(new BigInteger('123456', 16).bitLength(), 21)
    assert.equal(new BigInteger('123456789', 16).bitLength(), 33)
    assert.equal(new BigInteger('8023456789', 16).bitLength(), 40)
  })

  it('should add numbers', function () {
    assert.equal(new BigInteger('14').add(new BigInteger('26')).toString(16), '28')
    var k = new BigInteger('1234', 16)
    var r = k
    for (var i = 0; i < 257; i++)
      r = r.add(k)
    assert.equal(r.toString(16), '125868')

    var k = new BigInteger('abcdefabcdefabcdef', 16)
    var r = new BigInteger('deadbeef', 16)

    for (var i = 0; i < 257; i++) {
      r = r.add(k)
    }

    assert.equal(r.toString(16), 'ac79bd9b79be7a277bde')
  })

  it('should subtract numbers', function () {
    assert.equal(new BigInteger('14').subtract(new BigInteger('26')).toString(16), '-c')
    assert.equal(new BigInteger('26').subtract(new BigInteger('14')).toString(16), 'c')
    assert.equal(new BigInteger('26').subtract(new BigInteger('26')).toString(16), '0')
    assert.equal(new BigInteger('-26').subtract(new BigInteger('26')).toString(16), '-34')

    var a = new BigInteger('31ff3c61db2db84b9823d320907a573f6ad37c437abe458b1802cda041d6384a7d8daef41395491e2', 16)
    var b = new BigInteger('6f0e4d9f1d6071c183677f601af9305721c91d31b0bbbae8fb790000', 16)
    var r = new BigInteger('31ff3c61db2db84b9823d3208989726578fd75276287cd9516533a9acfb9a6776281f34583ddb91e2', 16)
    assert.equal(a.subtract(b).compareTo(r), 0)

    var r = b.subtract(new BigInteger('14'))
    assert.equal(b.clone().subtract(new BigInteger('14')).compareTo(r), 0)

    var r = new BigInteger('7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b', 16)
    assert.equal(r.subtract(new BigInteger('-1')).toString(16), '7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681c')

    // Carry and copy
    var a = new BigInteger('12345', 16)
    var b = new BigInteger('1000000000000', 16)
    assert.equal(a.subtract(b).toString(16), '-fffffffedcbb')

    var a = new BigInteger('12345', 16)
    var b = new BigInteger('1000000000000', 16)
    assert.equal(b.subtract(a).toString(16), 'fffffffedcbb')
  })

  it('should multiply numbers', function () {
    assert.equal(new BigInteger('1001', 16).multiply(new BigInteger('1234', 16)).toString(16), '1235234')
    assert.equal(new BigInteger('-1001', 16).multiply(new BigInteger('1234', 16)).toString(16), '-1235234')
    assert.equal(new BigInteger('-1001', 16).multiply(new BigInteger('-1234', 16)).toString(16), '1235234')
    var n = new BigInteger('1001', 16)
    var r = n

    for (var i = 0; i < 4; i++) {
      r = r.multiply(n)
    }

    assert.equal(r.toString(16), '100500a00a005001')

    var n = new BigInteger('79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798', 16)
    assert.equal(n.multiply(n).toString(16), '39e58a8055b6fb264b75ec8c646509784204ac15a8c24e05babc9729ab9b055c3a9458e4ce3289560a38e08ba8175a9446ce14e608245ab3a9978a8bd8acaa40')
    assert.equal(n.multiply(n).multiply(n).toString(16), '1b888e01a06e974017a28a5b4da436169761c9730b7aeedf75fc60f687b46e0cf2cb11667f795d5569482640fe5f628939467a01a612b023500d0161e9730279a7561043af6197798e41b7432458463e64fa81158907322dc330562697d0d600')

    assert.equal(new BigInteger('-100000000000').multiply(new BigInteger('3').divide(new BigInteger('4'))).toString(16), '0')
  })

  it('should divide numbers', function () {
    assert.equal(new BigInteger('10').divide(new BigInteger('256')).toString(16), '0')
    assert.equal(new BigInteger('69527932928').divide(new BigInteger('16974594')).toString(16), 'fff')
    assert.equal(new BigInteger('-69527932928').divide(new BigInteger('16974594')).toString(16), '-fff')

    var b = new BigInteger('39e58a8055b6fb264b75ec8c646509784204ac15a8c24e05babc9729ab9b055c3a9458e4ce3289560a38e08ba8175a9446ce14e608245ab3a9978a8bd8acaa40', 16)
    var n = new BigInteger('79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798', 16)
    assert.equal(b.divide(n).toString(16), n.toString(16))

    assert.equal(new BigInteger('1').divide(new BigInteger('-5')).toString(10), '0')

    // Regression after moving to word div
    var p = new BigInteger('fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f', 16)
    var a = new BigInteger('79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798', 16)
    var as = a.square()
    assert.equal(as.divide(p).toString(16), '39e58a8055b6fb264b75ec8c646509784204ac15a8c24e05babc9729e58090b9')
    var p = new BigInteger('ffffffff00000001000000000000000000000000ffffffffffffffffffffffff', 16)
    var a = new BigInteger('fffffffe00000003fffffffd0000000200000001fffffffe00000002ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 16)
    assert.equal(a.divide(p).toString(16), 'ffffffff00000002000000000000000000000001000000000000000000000001')
  })

  it('should mod numbers', function () {
    assert.equal(new BigInteger('10').mod(new BigInteger('256')).toString(16), 'a')
    assert.equal(new BigInteger('69527932928').mod(new BigInteger('16974594')).toString(16), '102f302')
    assert.equal(new BigInteger('-69527932928').mod(new BigInteger('16974594')).toString(16), '1000')
    assert.equal(new BigInteger('10', 16).mod(new BigInteger('256')).toString(16), '10')
    assert.equal(new BigInteger('100', 16).mod(new BigInteger('256')).toString(16), '0')
    assert.equal(new BigInteger('1001', 16).mod(new BigInteger('256')).toString(16), '1')
    assert.equal(new BigInteger('100000000001', 16).mod(new BigInteger('256')).toString(16), '1')
    assert.equal(new BigInteger('100000000001', 16).mod(new BigInteger('257')).toString(16), new BigInteger('100000000001', 16).mod(new BigInteger('257')).toString(16))
    assert.equal(new BigInteger('123456789012', 16).mod(new BigInteger('3')).toString(16), new BigInteger('123456789012', 16).mod(new BigInteger('3')).toString(16))

    var p = new BigInteger('ffffffff00000001000000000000000000000000ffffffffffffffffffffffff', 16)
    var a = new BigInteger('fffffffe00000003fffffffd0000000200000001fffffffe00000002ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 16)
    assert.equal( a.mod(p).toString(16), '0')
  })

  it('should shiftLeft numbers', function () {
    assert.equal(new BigInteger('69527932928').shiftLeft(13).toString(16), '2060602000000')
    assert.equal(new BigInteger('69527932928').shiftLeft(45).toString(16), '206060200000000000000')
  })

  it('should shiftRight numbers', function () {
    assert.equal(new BigInteger('69527932928').shiftRight(13).toString(16), '818180')
    assert.equal(new BigInteger('69527932928').shiftRight(17).toString(16), '81818')
    assert.equal(new BigInteger('69527932928').shiftRight(256).toString(16), '0')
  })

  it('should modInverse numbers', function () {
    var p = new BigInteger('257')
    var a = new BigInteger('3')
    var b = a.modInverse(p)
    assert.equal(a.multiply(b).mod(p).toString(16), '1')

    var p192 = new BigInteger('fffffffffffffffffffffffffffffffeffffffffffffffff', 16)
    var a = new BigInteger('deadbeef', 16)
    var b = a.modInverse(p192)
    assert.equal(a.multiply(b).mod(p192).toString(16), '1')
  })
})
