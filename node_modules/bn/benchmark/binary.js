var assert = require('assert')
var benchmark = require('benchmark')
benchmark.options.minTime = 1

var LocalBi = require('..').BigInteger
var NpmBi = require('bigi')

var fixtures = require('./fixtures/ops')

var suites = []
fixtures.forEach(function(f) {
  var flist = f.binary.results

  for (var name in flist) {
    (function(name) {
      var suite = new benchmark.Suite()
      suite.__name = name

      var localBi = new LocalBi(f.dec)
      var npmBi = new NpmBi(f.dec)

      var func1 = localBi[name]
      var func2 = npmBi[name]
      var term1 = new LocalBi(f.binary.term)
      var term2 = new NpmBi(f.binary.term)
      if (!func1) { throw new Error("missing local " + name); }
      if (!func2) { throw new Error("missing remote " + name); }

      var args1 = [term1]
      var args2 = [term2]
      var expected = f.binary.results[name]
      var e1, e2;
      if (Array.isArray(expected)) {
        e1 = expected[0];
        e2 = expected[1];
      } else {
        e1 = e2 = expected; 
      }

      suite.add('local#' + name, function() {
        var actual = func1.apply(localBi, args1)
        assert.equal(actual, e1)
      })

      suite.add('npm#' + name, function() {
        var actual = func2.apply(npmBi, args2)
        assert.equal(actual, e2)
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
