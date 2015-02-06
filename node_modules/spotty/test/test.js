#!/usr/bin/env node

var main = require('../')
main.tty(function(err, res) {
	if (err) {
		console.error(err.toString());
		process.exit(2)
	} else {
		console.log(res)
		process.exit(0);
	}
})