'use strict';

/*jshint node:true*/

var https = require('../');

var options = {
	socksPort: 9050, // Tor
	port: 443,
	hostname: 'en.wikipedia.org',
	protocol: 'https:',
	path: '/wiki/SOCKS'
};

var req = https.request(options, function(res) {
	var version;

	console.log('----------- STATUS -----------');
	console.log(res.statusCode);
	console.log('----------- HEADERS ----------');
	console.log(JSON.stringify(res.headers));
	res.setEncoding('utf8');

	version = process.version.substr(1).split('.');
	if (version[0] > 0 || version[1] > 8) {

		// The new way, using the readable stream interface (Node >= 0.10.0):
		res.on('readable', function() {
			console.log('----------- CHUNK ------------');
			console.log(res.read());
		});
	} else {

		// The old way, using 'data' listeners (Node <= 0.8.22):
		res.on('data', function(chunk) {
			console.log('----------- CHUNK ------------');
			console.log(chunk);
		});
	}
});

req.on('error', function(e) {
	console.log('problem with request: ' + e.message);
});

// GET request, so end without sending any data.
req.end();
