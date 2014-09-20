/**
 * @overview
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 */

'use strict';

/*jshint node:true*/

var https = require('https');
var url = require('url');

var Socks5ClientHttpsAgent = require('./lib/Agent');

exports.request = function(options, cb) {
	var agent;

	if (typeof options === 'string') {
		options = url.parse(options);
	}

	agent = new Socks5ClientHttpsAgent(options);
	options.agent = agent;

	return https.request(options, cb);
};

exports.get = function(options, cb) {
	var req = exports.request(options, cb);

	req.end();

	return req;
};
