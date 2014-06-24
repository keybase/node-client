(function (){

	var bigint = require("./wrap").engine;
	var zed = bigint(0);
	var one = bigint(1);

	function BigInteger (a,b) {
  	    if (!(this instanceof BigInteger))
            return new BigInteger(a,b);
		if (typeof(a) == 'string') {
			// Filter out any empty spaces.
			a = a.replace(/\s+/g,'');
			if (!b) { b = 10; }
			this._v = bigint(a,b);	
		} else if (typeof(a) == 'number') {
			this._v = bigint(a);
		} else if (typeof(a) == 'object' && Array.isArray(a)) {
			this._v = bigint.fromBuffer(new Buffer(a));
		} else if (a.constructor != zed.constructor) {
			throw new Error("failed to get valid inner object in constructor");	
		} else {
			this._v = a;
		}
	};

	function nbi() { return new BigInteger(bigint(0)); }
	function nbv(i) { return new BigInteger(bigint(i)); }

	function bigint_or_number(x) {
		if (typeof(x) === 'number') { return nbv(x); }
		else { return x; }
	};

	function buffer_to_array (b) {
		var ret = new Array();
		for (var i = 0; i < b.length; i++) {
			ret[i] = b.readUInt8(i);
		}
		return ret;
	};

	BigInteger.prototype.bitLength = function () {
		var ret;
		if (this.signum() == 0) { ret = 0; }
		else { ret = this._v.bitLength(); }
		return ret;
	};

	BigInteger.prototype.byteLength = function () { return (this.bitLength() >> 3); }

	BigInteger.prototype.modPowInt = function (i,n) {
		return new BigInteger(this._v.powm(bigint(i),n._v));
	};

	BigInteger.prototype.modInt = function (i) {
		return this._v.mod(bigint(i)).toNumber();
	};

	BigInteger.prototype.testBit = function (i) {
		var bi = one.shiftLeft(i);
		var tmp = this._v.and(bi);
		var ret = tmp.eq(zed) ? 0 : 1;
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
		var x = this._v.mod(m._v);

		// BigNum (and not BigInt) allows for mod outcome to be < 0
		if (x.cmp(zed) < 0) {
			x = x.add(m._v);
		}
		return new BigInteger(x);
	};

	BigInteger.prototype.abs = function () {
		return new BigInteger(this._v.abs());
	};

	BigInteger.prototype.pow = function (e) {
		return new BigInteger(this._v.pow(bigint_or_number(e)._v));
	};

	BigInteger.prototype.intValue = function () {
		return this._v.toNumber();
	};

	BigInteger.prototype.signum = function () {
		var cmp = this._v.cmp(zed);
		if (cmp > 0) { ret = 1; }
		else if (cmp === 0) { ret = 0; }
		else { ret = -1; }
		return ret;
	};

	BigInteger.prototype.negate = function () {
		return new BigInteger(this._v.neg());
	};

	BigInteger.prototype.equals = function (b) {
		return this._v.eq(b._v);
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
		if (this._v.ge(zed) && x._v.ge(zed)) {
			i = this._v.div(x._v);
		} else {
			var sign = this.signum() * x.signum();
			i = this._v.abs().div(x._v.abs());
			if (sign < 0) { i = i.neg(); }
		}
		return new BigInteger(i);
	};

	BigInteger.prototype.gcd = function (x) {
		return new BigInteger(this._v.gcd(x._v));
	};

	BigInteger.prototype.fromBuffer = function (x) {
		return new BigInteger(bigint.fromBuffer(x));
	};

	BigInteger.fromByteArrayUnsigned = function (b) {
		return BigInteger.fromBuffer(new Buffer(b));
	};

	BigInteger.fromBuffer = function (x) {
		return new BigInteger(bigint.fromBuffer(x));
	};

	BigInteger.fromDERInteger = function (buf) {
		var ret;
		if (buf.length == 0) { ret = BigInteger.ZERO; }
		else if (buf[0] == 0) { ret = BigInteger.fromBuffer(buf); }
		else {
			ret = BigInteger.fromBuffer(buf);
			if (buf[0] & 0x80) { 
				var z = BigInteger.ONE.shiftLeft(ret.bitLength())
				ret = ret.subtract(z);
			}
		}
		return ret;
	};

	BigInteger.prototype.compute_twos_complement = function () {
		// Compute 2's complement: 2^n - this
		// What should n be?  It should be rounded up to the next byte...
		// So keep in mind that -128 is encoded 0x80.  So it matters how
		// many bits (this+1) takes up.
		var l = this.add(BigInteger.ONE).bitLength();
		var bytes = Math.floor(l/8) + 1;
		var y = BigInteger.ONE.shiftLeft(bytes*8);

		// Compute the 2's-complement of this, which is 2^l - |this|.
		return y.add(this);
	};

	BigInteger.prototype.toDERInteger = function () {
		var ret = null;
		var s = this.signum();
		
		if (s == 0) { ret = new Buffer([0]); }
		else if (s < 0) {
			var z = this.compute_twos_complement();
			ret = z.toBuffer();
		} else {

			var ret = this.toBuffer();

			// If the high bit is on, and we're unsigned, we have to prepend a \x00
			// byte to show that we're positive.
			if (this.bitLength() % 8 == 0) {
				pad = new Buffer([0]);
				ret = Buffer.concat([ pad, ret ]);
			}
		}
		return buffer_to_array(ret);
	};

	BigInteger.prototype.divideAndRemainder = function (m) {
		var q = new BigInteger(this._v.div(m._v));
		var r = new BigInteger(this._v.mod(m._v));
		return [q,r];
	}

	BigInteger.fromString = function (s, base) {
		// Ignore the current object, that's cool....
		var bi;
		if (base === 256) {
			bi = bigint.fromBuffer(s);
		} else {
			bi = bigint(s, base);
		}
		return new BigInteger(bi);
	};

	BigInteger.prototype.fromString = function (s, base) {
		return BigInteger.fromString(s, base);
	};

	BigInteger.prototype.toByteArray = function () {
		var b = this.toBuffer();
		var l = b.length;
		var ret = new Array(l);
		for (var i = 0; i < l; i++) {
			ret[i] = b[i];	
		}
		return ret;
	};

	BigInteger.prototype.toByteArrayUnsigned = function () {
		return new Uint8Array(this.toBuffer());
	};

	BigInteger.prototype.toBuffer = function (size) {
		var ret = null;
		if (!size) { size = 0; }
		if (this.signum() == 0) { ret = new Buffer([]); }
		else { ret = this._v.toBuffer(); }
		if ((diff = size - ret.length) > 0) {
			var pad = new Buffer(diff);
			pad.fill(0);
			ret = Buffer.concat([pad, ret]);
		}
		return ret;
	};

	BigInteger.prototype.toHex = function(size) {
		var x = this;
		if (this.signum() < 0) {
			x = this.compute_twos_complement();
		}
		return x.toBuffer(size).toString('hex');
	};

	BigInteger.prototype.clone = function () {
		return new BigInteger(bigint(this._v));
	};

	BigInteger.prototype.getLowestSetBit = function () {
		var bl = this._v.bitLength();
		var ret = -1;
		var mask = bigint(1);
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

	BigInteger.prototype.isEven = function () {
		var mask = bigint(1);
		var res = mask.and(this._v);
		return res.eq(zed);
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

	BigInteger.fromHex = function (s) {
		if (!s.match(/^[a-fA-F0-9]*$/)) { throw new Error("hex string invalid: "+ s); }
		if (s.length % 2 != 0) { throw new Error("got an odd-length hex-string"); }
		return new BigInteger(s, 16);
	};

	BigInteger.prototype.inspect = function () {
		return "<BigInteger/fast " + this._v.toString() + ">";
	};

	BigInteger.prototype.toString = function (base) {
		if (!base) { base = 10; }
		var raw = this._v.toString(base);
		if (raw.length == 0) {
			raw = "0";	
		} else if (base == 16 && raw.length > 1) {
			if (raw[0] == "0") {
				raw = raw.slice(1);
			} else if (raw.slice(0,2) == "-0") {
				raw = "-" + raw.slice(2);
			}
		}
		return raw;
	};

	BigInteger.valueOf = function (x) {
		return bigint_or_number(x);
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
