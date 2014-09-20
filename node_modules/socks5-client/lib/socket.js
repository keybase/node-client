/**
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 * @preserve
 *
 * Portions of this code are copyright (c) 2011 Valentin Háloiu, redistributed and modified under the following license (MIT).
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

'use strict';

/*jshint node:true*/

var net = require('net');
var EventEmitter = require('events').EventEmitter;
var inherits = require('util').inherits;

var htons = require('network-byte-order').htons;
var ipv6 = require('ipv6').v6;

module.exports = exports = Socks5ClientSocket;

exports.createConnection = function(options) {
	var socksSocket, socksHost, socksPort;

	socksHost = options.socksHost || 'localhost';
	socksPort = options.socksPort || 1080;
	socksSocket = new Socks5ClientSocket(socksHost, socksPort);

	return socksSocket.connect(options.port, options.host);
};

function Socks5ClientSocket(socksHost, socksPort) {
	var self = this;

	EventEmitter.call(self);

	self.socket = new net.Socket();
	self.socksHost = socksHost;
	self.socksPort = socksPort;

	self.socket.on('error', function(err) {
		self.emit('error', err);
	});

	self.on('error', function(err) {
		if (!self.socket.destroyed) {
			self.socket.destroy();
		}
	});
}

inherits(Socks5ClientSocket, EventEmitter);

Socks5ClientSocket.prototype.setTimeout = function(msecs, callback) {
	return this.socket.setTimeout(msecs, callback);
};

Socks5ClientSocket.prototype.setNoDelay = function() {
	return this.socket.setNoDelay();
};

Socks5ClientSocket.prototype.setKeepAlive = function(setting, msecs) {
	return this.socket.setKeepAlive(setting, msecs);
};

Socks5ClientSocket.prototype.address = function() {
	return this.socket.address();
};

Socks5ClientSocket.prototype.pause = function() {
	return this.socket.pause();
};

Socks5ClientSocket.prototype.resume = function() {
	return this.socket.resume();
};

Socks5ClientSocket.prototype.end = function(data, encoding) {
	return this.socket.end(data, encoding);
};

Socks5ClientSocket.prototype.destroy = function(exception) {
	return this.socket.destroy(exception);
};

Socks5ClientSocket.prototype.destroySoon = function() {
	var ret = this.socket.destroySoon();

	this.writable = false; // node's http library asserts writable to be false after destroySoon

	return ret;
};

Socks5ClientSocket.prototype.setEncoding = function(encoding) {
	return this.socket.setEncoding(encoding);
};

Socks5ClientSocket.prototype.write = function(data, arg1, arg2) {
	return this.socket.write(data, arg1, arg2);
};

Socks5ClientSocket.prototype.connect = function(port, host) {
	var self = this;

	self.socket.connect(self.socksPort, self.socksHost, function() {
		self.establishSocksConnection(host, port);
	});

	return self;
};

Socks5ClientSocket.prototype.handleSocksConnectToHost = function() {
	var self = this;

	self.socket.on('close', function(hadError) {
		self.emit('close', hadError);
	});

	self.socket.on('end', function() {
		self.emit('end');
	});

	self.socket.on('data', function(data) {
		self.emit('data', data);
	});

	self.socket._httpMessage = self._httpMessage;
	self.socket.parser = self.parser;
	self.socket.ondata = self.ondata;
	self.writable = true;
	self.readable = true;
	self.emit('connect');
};

Socks5ClientSocket.prototype.establishSocksConnection = function(host, port) {
	var self = this;

	self.authenticateWithSocks(function() {
		self.connectSocksToHost(host, port, function() {
			self.handleSocksConnectToHost();
		});
	});
};

Socks5ClientSocket.prototype.authenticateWithSocks = function(cb) {
	var request, self = this;

	self.socket.ondata = function(d, start, end) {
		var error;

		if (end - start !== 2) {
			error = new Error('SOCKS authentication failed. Unexpected number of bytes received.');
		} else if (d[start] !== 0x05) {
			error = new Error('SOCKS authentication failed. Unexpected SOCKS version number: ' + d[start] + '.');
		} else if (d[start + 1] !== 0x00) {
			error = new Error('SOCKS authentication failed. Unexpected SOCKS authentication method: ' + d[start+1] + '.');
		}

		if (error) {
			self.emit('error', error);
			return;
		}

		if (cb) {
			cb();
		}
	};

	request = new Buffer(3);
	request[0] = 0x05;  // SOCKS version
	request[1] = 0x01;  // number of authentication methods
	request[2] = 0x00;  // no authentication
	self.socket.write(request);
};

Socks5ClientSocket.prototype.connectSocksToHost = function(host, port, cb) {
	var buffer, request, self = this;

	this.socket.ondata = function(d, start, end) {
		var i, address, addressLength, error;

		if (d[start] !== 0x05) {
			error = new Error('SOCKS connection failed. Unexpected SOCKS version number: ' + d[start] + '.');
		} else if (d[start + 1] !== 0x00) {
			error = new Error('SOCKS connection failed. ' + getErrorMessage(d[start + 1]) + '.');
		} else if (d[start + 2] !== 0x00) {
			error = new Error('SOCKS connection failed. The reserved byte must be 0x00.');
		}

		if (error) {
			self.emit('error', error);
			return;
		}

		address = '';
		addressLength = 0;

		switch (d[start + 3]) {
			case 1:
				address = d[start + 4] + '.' + d[start + 5] + '.' + d[start + 6] + '.' + d[start + 7];
				addressLength = 4;
				break;
			case 3:
				addressLength = d[start + 4] + 1;
				for (i = start + 5; i < start + addressLength; i++) {
					address += String.fromCharCode(d[i]);
				}
				break;
			case 4:
				addressLength = 16;
				break;
			default:
				self.emit('error', new Error('SOCKS connection failed. Unknown addres type: ' + d[start + 3] + '.'));
				return;
		}

		if (cb) {
			cb();
		}
	};

	buffer = [];
	buffer.push(0x05); // SOCKS version
	buffer.push(0x01); // Command code: establish a TCP/IP stream connection
	buffer.push(0x00); // Reserved - myst be 0x00

	switch (net.isIP(host)) {
		case 0:
			buffer.push(0x03);
			parseDomainName(host, buffer);
			break;
		case 4:
			buffer.push(0x01);
			parseIPv4(host, buffer);
			break;
		case 6:
			buffer.push(0x04);
			if (parseIPv6(host, buffer) === false) {
				self.emit('error', new Error('IPv6 host parsing failed. Invalid address.'));
				return;
			}
			break;
	}

	parsePort(port, buffer);

	request = new Buffer(buffer);
	this.socket.write(request);
};

function parseIPv4(host, buffer) {
	var i, ip, groups = host.split('.');

	for (i = 0; i < groups.length; i++) {
		ip = parseInt(groups[i], 10);
		buffer.push(ip);
	}
}

function parseIPv6(host, buffer) {
	var i, b1, b2, part1, part2, address, groups;

	address = new ipv6.Address(host).canonicalForm();
	if (!address) {
		return false;
	}

	groups = address.split(':');

	for (i = 0; i < groups.length; i++) {
		part1 = groups[i].substr(0,2);
		part2 = groups[i].substr(2,2);

		b1 = parseInt(part1, 16);
		b2 = parseInt(part2, 16);

		buffer.push(b1);
		buffer.push(b2);
	}

	return true;
}

function parseDomainName(host, buffer) {
	var i, c;

	buffer.push(host.length);
	for (i = 0; i < host.length; i++) {
		c = host.charCodeAt(i);
		buffer.push(c);
	}
}

function parsePort(port, buffer) {
	htons(buffer, buffer.length, port);
}

function getErrorMessage(code) {
	switch (code) {
		case 1:
			return 'General SOCKS server failure';
		case 2:
			return 'Connection not allowed by ruleset';
		case 3:
			return 'Network unreachable';
		case 4:
			return 'Host unreachable';
		case 5:
			return 'Connection refused';
		case 6:
			return 'TTL expired';
		case 7:
			return 'Command not supported';
		case 8:
			return 'Address type not supported';
		default:
			return 'Unknown status code ' + code;
	}
}
