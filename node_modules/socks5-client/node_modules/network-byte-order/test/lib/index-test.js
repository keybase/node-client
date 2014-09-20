/**
 * @author Matthew Caruana Galizia <m@m.cg>
 * @license MIT: http://mattcg.mit-license.org/
 * @copyright Copyright (c) 2013, Matthew Caruana Galizia
 */

/*jshint node:true*/
/*global test, suite*/

'use strict';

var assert = require('assert');
var nbo = require(process.env.TEST_LIB_PATH);

suite('tags', function() {

	test('htons()', function() {
		var b;

		b = [];
		nbo.htons(b, 0, 80);
		assert.deepEqual(b, [0, 80]);

		b = [];
		nbo.htons(b, 0, 2048);
		assert.deepEqual(b, [8, 0]);

		b = [];
		nbo.htons(b, 0, 65536);
		assert.deepEqual(b, [0, 0]);
	});

	test('htonl()', function() {
		var b;

		b = [];
		nbo.htonl(b, 0, 80);
		assert.deepEqual(b, [0, 0, 0, 80]);

		b = [];
		nbo.htonl(b, 0, 2147483647);
		assert.deepEqual(b, [127, 255, 255, 255]);

		b = [];
		nbo.htonl(b, 0, 4294967295);
		assert.deepEqual(b, [255, 255, 255, 255]);

		b = [];
		nbo.htonl(b, 0, 4294967296);
		assert.deepEqual(b, [0, 0, 0, 0]);
	});

	test('ntohs()', function() {
		assert.equal(nbo.ntohs([0, 80], 0), 80);
		assert.equal(nbo.ntohs([8, 0], 0), 2048);
		assert.equal(nbo.ntohs([0, 0], 0), 0);
	});

	test('ntohl()', function() {
		assert.equal(nbo.ntohl([0, 0, 0, 80], 0), 80);
		assert.equal(nbo.ntohl([127, 255, 255, 255], 0), 2147483647);
		assert.equal(nbo.ntohl([0, 0, 0, 0], 0), 0);
	});

	test('ntohlStr()', function() {
		assert.equal(nbo.ntohlStr(String.fromCharCode(0, 0, 0, 80), 0), 80);
		assert.equal(nbo.ntohlStr(String.fromCharCode(127, 255, 255, 255), 0), 2147483647);
		assert.equal(nbo.ntohlStr(String.fromCharCode(0, 0, 0, 0), 0), 0);
	});

	test('ntohsStr()', function() {
		assert.equal(nbo.ntohsStr(String.fromCharCode(0, 80), 0), 80);
		assert.equal(nbo.ntohsStr(String.fromCharCode(8, 0), 0), 2048);
		assert.equal(nbo.ntohsStr(String.fromCharCode(0, 0), 0), 0);
	});
});
