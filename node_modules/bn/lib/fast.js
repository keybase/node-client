(function (){

	var bigint = require("./wrap").engine;

	function BigInteger (v) {
		this._v = v
	}

	function nbi() { return new BigInteger(bigint(0)); }
	function nbv(i) { return new BigInteger(bigint(i)); }

	BigInteger.prototype.bitLength = function () {
		return this._v.bitLength();
	};

	BigInteger.prototype.modPowInt = function (i,n) {
		return new BigInteger(this._v.powm(bigint(i),n._v));
	};

	BigInteger.prototype.modInt = function (i) {
		return this._v.mod(bigint(i)).toNumber();
	};

	BigInteger.prototype.testBit = function (i) {
		var bi = bigint(1).shiftLeft(i);
		var tmp = this._v.and(bi);
		var ret = tmp.eq(bigint(0)) ? 0 : 1;
		return ret;
	};

	BigInteger.prototype.setBit = function (i) {
		var mask = bigint(1).shiftLeft(i);
		return new BigInteger(this._v.or(mask));
	};

	BigInteger.prototype.shiftLeft = function (i) {
		return new BigInteger(this._v.shiftLeft(i));
	};

	BigInteger.prototype.shiftRight = function (i) {
		return new BigInteger(this._v.shiftRight(i));
	};

	BigInteger.prototype.compareTo = function (b) {
		return this._v.cmp(b._v);
	};

	BigInteger.prototype.modPow = function (e, n) {
		return new BigInteger(this._v.powm(e._v, n._v));
	};

	BigInteger.prototype.square = function() {
		return new BigInteger(this._v.mul(this._v));
	};

	BigInteger.prototype.mod = function (m) {
		return new BigInteger(this._v.mod(m._v));
	};

	BigInteger.prototype.intValue = function () {
		return this._v.toNumber();
	};

	BigInteger.prototype.subtract = function (x) {
		return new BigInteger(this._v.sub(x._v));
	};

	BigInteger.prototype.add = function(x) {
		return new BigInteger(this._v.add(x._v));
	};

	BigInteger.prototype.multiply = function (x) {
		return new BigInteger(this._v.mul(x._v));
	};

	BigInteger.prototype.divide = function (x) {
		return new BigInteger(this._v.div(x._v));
	};

	BigInteger.prototype.gcd = function (x) {
		return new BigInteger(this._v.gcd(x._v));
	};

	BigInteger.prototype.fromBuffer = function (x) {
		return new BigInteger(bigint.fromBuffer(x));
	};
	BigInteger.prototype.divideAndRemainder = function (m) {
		var q = new BigInteger(this._v.div(m._v));
		var r = new BigInteger(this._v.mod(m._v));
		return [q,r];
	}

	BigInteger.prototype.fromString = function (s, base) {
		// Ignore the current object, that's cool....
		var bi;
		if (base === 256) {
			bi = bigint.fromBuffer(s);
		} else {
			bi = bigint(s, base);
		}
		return new BigInteger(bi);
	};

	BigInteger.prototype.toByteArray = function () {
		return this._v.toBuffer();
	};

	BigInteger.prototype.getLowestSetBit = function () {
		var bl = this._v.bitLength();
		var ret = -1;
		var mask = bigint(1);
		var zed = bigint(0);
		for (var i = 0; i < bl && ret < 0; i++) {
			if (!mask.and(this._v).eq(zed)) {
				ret = i;
			} else {
				mask = mask.shiftLeft(1);
			}
		}
		return ret;
	};

	BigInteger.prototype.modInverse = function (n) {
		return new BigInteger(this._v.invertm(n._v));
	};

	// returns bit length of the integer x. stolen from 
	// elsewhere is jsbn.
	function nbits(x) {
  		var r = 1, t;
  		if((t=x>>>16) != 0) { x = t; r += 16; }
  		if((t=x>>8) != 0) { x = t; r += 8; }
  		if((t=x>>4) != 0) { x = t; r += 4; }
  		if((t=x>>2) != 0) { x = t; r += 2; }
  		if((t=x>>1) != 0) { x = t; r += 1; }
  		return r;
	};

	BigInteger.random_nbit = function (nbits, rf) {
		var nbytes = Math.ceil(nbits / 8);
		var buf = new Buffer(nbytes);
		rf.nextBytes(buf);
		var ret = bigint.fromBuffer(buf);
		var mask = bigint(1).shiftLeft(nbits).sub(bigint(1));
		ret = ret.and(mask);
		return new BigInteger(ret);
	};


	BigInteger.ZERO = nbv(0);
	BigInteger.ONE = nbv(1);

	module.exports = {
		BigInteger : BigInteger,
		nbi : nbi,
		nbv : nbv,
		nbits : nbits
	};

})(this);