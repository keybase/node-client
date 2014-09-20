/**
 * @overview
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 * @preserve
 */

'use strict';

/*jshint node:true*/

var http = require('http');
var url = require('url');

var Socks5ClientHttpAgent = require('./lib/Agent');

exports.request = function(options, cb) {
	var agent;

	if (typeof options === 'string') {
		options = url.parse(options);
	}

	agent = new Socks5ClientHttpAgent(options);
	options.agent = agent;

	return http.request(options, cb);
};

exports.get = function(options, cb) {
	var req = exports.request(options, cb);

	req.end();

	return req;
};
