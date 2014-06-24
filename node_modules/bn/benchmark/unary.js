var assert = require('assert')
var benchmark = require('benchmark')
benchmark.options.minTime = 1

var LocalBi = require('..').BigInteger
var NpmBi = require('bigi')

var fixtures = require('./fixtures/ops')

var suites = []
fixtures.forEach(function(f) {
  var flist = f.unary

  for (var name in flist) {
    (function(name) {
      var suite = new benchmark.Suite()
      suite.__name = name

      var localBi = new LocalBi(f.dec)
      var npmBi = new NpmBi(f.dec)

      var func1 = localBi[name]
      var func2 = npmBi[name]
      var args = f.unary[name].args
      var expected = f.unary[name].result

      suite.add('local#' + name, function() {
        var actual = func1.apply(localBi, args)
        assert.equal(actual, expected)
      })

      suite.add('npm#' + name, function() {
        var actual = func2.apply(npmBi, args)
        assert.equal(actual, expected)
      })

      // after each cycle
      suite.on('cycle', function (event) {
        console.log('*', String(event.target))
      })

      // other handling
      suite.on('complete', function() {
        console.log('')
        console.log('Fastest is ' + this.filter('fastest').pluck('name'));
      })

      suite.on('error', function(event) {
        throw event.target.error
      })

      suites.push(suite)
    })(name)
  }
})

// run tests after set up, less chance of error
suites.forEach(function(suite) {
  console.log('--------------------------------------------------')
  console.log('Benchmarking: ' + suite.__name);

  suite.run()
})
