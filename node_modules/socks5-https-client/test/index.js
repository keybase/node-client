/**
 * @overview
 * @author Matthew Caruana Galizia <m@m.cg>
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 * @license MIT
 * @preserve
 */

'use strict';

/*jshint node:true*/
/*global test, suite, setup*/

var assert = require('assert');
var net = require('net');
var socks = require('node-socks/socks.js');
var https = require('../');

var version = process.version.substr(1).split('.');
var readableStreams = version[0] > 0 || version[1] > 8;

suite('socks5-https-client tests', function() {
	var server;

	this.timeout(5000);

	setup(function(done) {
		server = socks.createServer(function(socket, port, address, proxyReady) {
			var proxy;

			proxy = net.createConnection(port, address, proxyReady);

			proxy.on('data', function(data) {
				socket.write(data);
			});

			socket.on('data', function(data) {
				proxy.write(data);
			});

			proxy.on('close', function() {
				socket.end();
			});

			socket.on('close', function() {
				proxy.removeAllListeners('data');
				proxy.end();
			});
		});

		server.listen(1080, 'localhost', 511, function() {
			done();
		});

		server.on('error', function(err) {
			throw err;
		});
	});

	test('simple request', function(done) {
		var req;

		req = https.request({
			hostname: 'encrypted.google.com',
			path: '/'
		}, function(res, err) {
			var data = '';

			assert.ifError(err);
			assert.equal(res.statusCode, 200);

			res.setEncoding('utf8');

			if (readableStreams) {

				// The new way, using the readable stream interface (Node >= 0.10.0):
				res.on('readable', function() {
					data += res.read();
				});
			} else {

				// The old way, using 'data' listeners (Node <= 0.8.22):
				res.on('data', function(chunk) {
					data += chunk;
				});
			}

			res.on('end', function() {
				assert(-1 !== data.indexOf('<html'));
				assert(-1 !== data.indexOf('</html>'));

				done();
			});
		});

		req.on('error', function(err) {
			assert.fail(err);
		});

		// GET request, so end without sending any data.
		req.end();
	});
});
