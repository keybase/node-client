
var engine = require('./lib/wrap').engine;
if (!engine) {
	syms = require("./lib/pure");
} else {
	syms = require("./lib/fast");
}

for (var k in syms) {
	exports[k] = syms[k];	
}
