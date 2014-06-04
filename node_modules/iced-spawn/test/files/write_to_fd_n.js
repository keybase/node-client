#!/usr/bin/env node

exports.skip = true;
var fs = require('fs');
var fd = parseInt(process.argv[2], 10)
var msg = process.argv[3];
var buf = new Buffer(msg, 'utf8');
fs.write(fd, buf, 0, buf.length, null, function (err) {
	rc = 0;
	if (err) {
		console.error("Failed to write to " + fd + ":");
		console.error(err);
		rc = 2;
	}
	process.exit(rc);
});
