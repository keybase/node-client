var globToRegexp = require("./index.js");
var assert = require("assert");

function assertMatch(glob, str, opts) {
  assert.ok(globToRegexp(glob, opts).test(str));
}

function assertNotMatch(glob, str, opts) {
  assert.equal(false, globToRegexp(glob, opts).test(str));
}

// Match everything
assertMatch("*", "foo");

// Match the end
assertMatch("f*", "foo");

// Match the start
assertMatch("*o", "foo");

// Match the middle
assertMatch("f*uck", "firetruck");

// Match zero characters
assertMatch("f*uck", "fuck");

// More complex matches
assertMatch("*.min.js", "http://example.com/jquery.min.js");
assertMatch("*.min.*", "http://example.com/jquery.min.js")
assertMatch("*/js/*.js", "http://example.com/js/jquery.min.js")

var testStr = "\\/$^+?.()=!|{},[].*"
assertMatch(testStr, testStr);

// Extended mode

// ?: Match one character, no more and no less
assertMatch("f?o", "foo", { extended: true });
assertNotMatch("f?o", "fooo", { extended: true });
assertNotMatch("f?oo", "foo", { extended: true });

// []: Match a character range
assertMatch("fo[oz]", "foo", { extended: true });
assertMatch("fo[oz]", "foz", { extended: true });
assertNotMatch("fo[oz]", "fog", { extended: true });

// {}: Match a choice of different substrings
assertMatch("foo{bar,baaz}", "foobaaz", { extended: true });
assertMatch("foo{bar,baaz}", "foobar", { extended: true });
assertNotMatch("foo{bar,baaz}", "foobuzz", { extended: true });
assertMatch("foo{bar,b*z}", "foobuzz", { extended: true });

// More complex extended matches
assertMatch("http://?o[oz].b*z.com/{*.js,*.html}",
            "http://foo.baaz.com/jquery.min.js",
            { extended: true });
assertMatch("http://?o[oz].b*z.com/{*.js,*.html}",
            "http://moz.buzz.com/index.html",
            { extended: true });
assertNotMatch("http://?o[oz].b*z.com/{*.js,*.html}",
               "http://moz.buzz.com/index.htm",
               { extended: true });
assertNotMatch("http://?o[oz].b*z.com/{*.js,*.html}",
               "http://moz.bar.com/index.html",
               { extended: true });
assertNotMatch("http://?o[oz].b*z.com/{*.js,*.html}",
               "http://flozz.buzz.com/index.html",
               { extended: true });

// Remaining special chars should still match themselves
var testExtStr = "\\/$^+.()=!|,.*"
assertMatch(testExtStr, testExtStr, { extended: true });

console.log("Ok!");
