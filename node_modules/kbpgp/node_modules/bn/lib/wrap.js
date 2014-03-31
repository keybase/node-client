
var engine = null;
var modules = [ "bigint", "bignum" ];
for (var i in modules) {
	try {
		engine = require(modules[i]);
		break;
	} catch (e) {}
}
exports.engine = engine;