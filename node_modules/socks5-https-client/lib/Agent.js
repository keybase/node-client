/**
 * @overview
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 */

'use strict';

/*jshint node:true*/

var http = require('http');
var inherits = require('util').inherits;

var socksClient = require('socks5-client');
var starttls = require('starttls');

function createConnection(options) {
	var socksSocket, handleSocksConnectToHost;

	socksSocket = socksClient.createConnection(options);

	handleSocksConnectToHost = socksSocket.handleSocksConnectToHost;
	socksSocket.handleSocksConnectToHost = function() {
		var verifyHost;

		if (options.rejectUnauthorized !== false) {
			verifyHost = options.hostname;
		}

		starttls({
			socket: socksSocket.socket,
			host: verifyHost
		}, function(err) {
			var clearText;

			// Add authorization properties to the client object as libraries like 'request' expect them there.
			clearText = this.cleartext;
			socksSocket.authorized = clearText.authorized;
			socksSocket.authorizationError = clearText.authorizationError;

			if (err) {
				return socksSocket.emit('error', err);
			}

			socksSocket.socket = clearText;

			handleSocksConnectToHost.call(socksSocket);
	
			// The Socks5ClientSocket constructor (invoked by socksClient.createConnection) adds an 'error' event listener to the original socket. That behaviour needs to be mimicked by adding a similar listener to the cleartext stream, which replaces the original socket.
			clearText.on('error', function(err) {
				socksSocket.emit('error', err);
			});
		});
	};

	return socksSocket;
}

function Socks5ClientHttpsAgent(options) {
	http.Agent.call(this, options);

	this.socksHost = options.socksHost || 'localhost';
	this.socksPort = options.socksPort || 1080;
	this.createConnection = createConnection;
}

inherits(Socks5ClientHttpsAgent, http.Agent);

module.exports = Socks5ClientHttpsAgent;
