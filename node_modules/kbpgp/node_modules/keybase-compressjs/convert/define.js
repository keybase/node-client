

module.exports = function (list, fn) {
	var code = "var libs = [\n";
	for (var i = 0; i < list.length; i++) {
		var mod = list[i];
		code += "\trequire('" + mod + "')";
		if (i < list.length - 1) { code += ","; }
		code += "\n"
	}
	code += "];\n"
	code += "var body_fn = " + fn.toString() + ";\n"
	code += "module.exports = body_fn.apply(null, libs);"
	console.log(code);
};

