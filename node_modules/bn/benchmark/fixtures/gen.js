var BigInteger = require('../..')

function randomNum(bits) {
  var num = BigInteger.ZERO

  for (var i = 0; i < bits; i += 8) {
    var rand = BigInteger.valueOf((Math.random() * 255) & 255)

    num = num.add(rand.shiftLeft(i))
  }

  return num
}

var results = [128, 160, 256].map(function(bits) {
  var a, b

  while (true) {
    a = randomNum(bits)
    b = randomNum(bits)

    // a = Math.max(a, b), b = Math.min(a, b)
    if (b.compareTo(a) >= 0) {
      var t = a
      a = b
      b = t
    }

    var r1 = a.mod(b).signum() !== 0
    var r2 = a.modInverse(b).signum() !== 0

    if (r1 && r2) break
  }

  var results = {
    dec: a.toString(10),
    hex: a.toString(16),
    unary: {
      bitLength: {
        result: a.bitLength()
      },
      pow: {
        args: [3],
        result: a.pow(3).toString()
      },
      shiftLeft: {
        args: [3],
        result: a.shiftLeft(3).toString()
      },
      shiftRight: {
        args: [3],
        result: a.shiftRight(3).toString()
      },
      signum: {
        result: a.signum().toString()
      },
      square: {
        result: a.square().toString()
      },
      testBit: {
        args: [64],
        result: a.testBit(64)
      }
    },
    binary: {
      term: b.toString(),
      results: {
        add: a.add(b).toString(),
        compareTo: a.compareTo(b).toString(),
        divide: a.divide(b).toString(),
        mod: a.mod(b).toString(),
        modInverse: a.modInverse(b).toString(),
        multiply: a.multiply(b).toString(),
        subtract: a.subtract(b).toString()
      }
    }
  }

  return results
})

console.log(JSON.stringify(results, null, '  '))
