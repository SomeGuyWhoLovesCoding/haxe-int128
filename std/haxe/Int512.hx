/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package haxe;

using haxe.Int512;

/**
	A cross-platform signed 512-bit integer.
	Int512 instances can be created from two 256-bit words using `Int512.make()`.
	NOTE: This class is a beta.
**/
#if flash
@:notNull
#end
@:transitive
abstract Int512(__Int512) from __Int512 to __Int512 {
	private inline function new(x:__Int512)
		this = x;

	/**
		Makes a copy of `this` Int512.
	**/
	public inline function copy():Int512
		return Int512.make(high, low);

	/**
		Construct an Int512 from two 256-bit words `high` and `low`.
	**/
	public static inline function make(high:Int256, low:Int256):Int512
		return new Int512(new __Int512(high, low));

	/**
		Returns an Int512 with the value of the Int `x`.
		`x` is sign-extended to fill 256 bits.
	**/
	@:from public static inline function ofInt(x:Int):Int512
		#if lua return make((x : Int32) >> 31, (x : Int32)); #else return make(x >> 31, x); #end

	/**
		Returns an Int512 with the value of the Int64 `x`.
		`x` is sign-extended to fill 256 bits.
	**/
	@:from public static inline function ofInt64(x:Int64):Int512
		#if lua return make((x : Int64) >> 63, (x : Int64)); #else return make(x >> 63, x); #end

	/**
		Returns an Int512 with the value of the 128 `x`.
		`x` is sign-extended to fill 256 bits.
	**/
	@:from public static inline function ofInt128(x:Int128):Int512
		#if lua return make((x : Int128) >> 127, (x : Int128)); #else return make(x >> 127, x); #end

	/**
		Returns an Int512 with the value of the 128 `x`.
		`x` is sign-extended to fill 256 bits.
	**/
	@:from public static inline function ofInt256(x:Int256):Int512
		#if lua return make((x : Int256) >> 255, (x : Int256)); #else return make(x >> 255, x); #end

	/**
		Returns an Int with the value of the Int512 `x`.
		Throws an exception  if `x` cannot be represented in 32 bits.
	**/
	public static inline function toInt(x:Int512):Int {
		return Int256.toInt(x.low);
	}

	/**
		Returns an Int with the value of the Int512 `x`.
		Throws an exception  if `x` cannot be represented in 32 bits.
	**/
	public static inline function toInt64(x:Int512):Int64 {
		return Int256.toInt64(x.low);
	}

	/**
		Returns an Int128 with the value of the Int512 `x`.
		Throws an exception  if `x` cannot be represented in 128 bits.
	**/
	public static inline function toInt128(x:Int512):Int128 {
		return Int256.toInt128(x.low);
	}

	/**
		Returns an Int64 with the value of the Int512 `x`.
		Throws an exception  if `x` cannot be represented in 256 bits.
	**/
	public static inline function toInt256(x:Int512):Int256 {
		var res:Int256 = x.low;

		// This is a completely different and overflow check because we're using Int512's.
		// It can only be triggered if you input an Int512 as the function parameter.
		if ((!isNeg(x) && Int512.isNeg(res)) || (x.high != x.low >> 255))
			throw "Overflow";

		return res.copy();
	}

	@:deprecated('haxe.Int512.is() is deprecated. Use haxe.Int512.isInt512() instead')
	inline public static function is(val:Dynamic):Bool {
		return isInt512(val);
	}

	/**
		Returns whether the value `val` is of type `haxe.Int512`
	**/
	inline public static function isInt512(val:Dynamic):Bool
		return Std.isOfType(val, __Int512);

	/**
		Returns `true` if `x` is less than zero.
	**/
	public static inline function isNeg(x:Int512):Bool
		return x.high < 0 && x.high.high < 0;

	/**
		Returns `true` if `x` is exactly zero.
	**/
	public static inline function isZero(x:Int512):Bool
		return x == 0;

	/**
		Compares `a` and `b` in signed mode.
		Returns a negative value if `a < b`, positive if `a > b`,
		or 0 if `a == b`.
	**/
	public static inline function compare(a:Int512, b:Int512):Int256 {
		var v = a.high - b.high;
		v = if (v != 0) v else Int256.ucompare(a.low, b.low);
		return a.high < 0 ? (b.high < 0 ? v : -1) : (b.high >= 0 ? v : 1);
	}

	/**
		Compares `a` and `b` in unsigned mode.
		Returns a negative value if `a < b`, positive if `a > b`,
		or 0 if `a == b`.
	**/
	public static inline function ucompare(a:Int512, b:Int512):Int256 {
		var v = Int256.ucompare(a.high, b.high);
		return if (v != 0) v else Int256.ucompare(a.low, b.low);
	}

	/**
		Returns a signed decimal `String` representation of `x`.
	**/
	public static inline function toStr(x:Int512):String
		return x.toString();

	function toString():String {
		var i:Int512 = cast this;
		if (i == 0)
			return "0";
		var str = "";
		var neg = false;
		if (i.isNeg()) {
			neg = true;
			// i = -i; cannot negate here as --57896044618658097711785492504343953926634992332820282019728792003956564819968 = -57896044618658097711785492504343953926634992332820282019728792003956564819968
		}
		var ten:Int512 = Int512.ofInt(10);
		while (i != 0) {
			var r = i.divMod(ten);
			if (r.modulus.isNeg()) {
				str = -(r.modulus).low + str;
				i = -r.quotient;
			} else {
				str = r.modulus.low + str;
				i = r.quotient;
			}
		}
		if (neg)
			str = "-" + str;
		return str;
	}

	public static inline function parseString(sParam:String):Int512 {
		return Int512Helper.parseString(sParam);
	}

	public static inline function fromFloat(f:Float):Int512 {
		return Int512Helper.fromFloat(f);
	}

	/**
		Performs signed integer divison of `dividend` by `divisor`.
		Returns `{ quotient : Int512, modulus : Int512 }`.
	**/
	public static function divMod(dividend:Int512, divisor:Int512):{quotient:Int512, modulus:Int512} {
		// Handle special cases of 0 and 1
		if (divisor.high == 0) {
			switch (Int256.toInt(divisor.low)) {
				case 0:
					throw "divide by zero";
				case 1:
					return {quotient: dividend.copy(), modulus: 0};
			}
		}

		var divSign = dividend.isNeg() != divisor.isNeg();

		var modulus = dividend.isNeg() ? -dividend : dividend.copy();
		divisor = divisor.isNeg() ? -divisor : divisor;

		var quotient:Int512 = 0;
		var mask:Int512 = 1;

		while (!divisor.isNeg()) {
			var cmp = ucompare(divisor, modulus);
			divisor <<= 1;
			mask <<= 1;
			if (cmp >= 0)
				break;
		}

		while (mask != 0) {
			if (ucompare(modulus, divisor) >= 0) {
				quotient |= mask;
				modulus -= divisor;
			}
			mask >>>= 1;
			divisor >>>= 1;
		}

		if (divSign)
			quotient = -quotient;
		if (dividend.isNeg())
			modulus = -modulus;

		return {
			quotient: quotient,
			modulus: modulus
		};
	}

	/**
		Returns the negative of `x`.
	**/
	@:op(-A) public static inline function neg(x:Int512):Int512 {
		var high = ~x.high;
		var low = -x.low;
		if (low == 0)
			high++;
		return make(high, low);
	}

	@:op(++A) private inline function preIncrement():Int512 {
		this = copy();
		this.low++;
		if (this.low == 0)
			this.high++;
		return cast this;
	}

	@:op(A++) private inline function postIncrement():Int512 {
		var ret = this;
		preIncrement();
		return ret;
	}

	@:op(--A) private inline function preDecrement():Int512 {
		this = copy();
		if (this.low == 0)
			this.high--;
		this.low--;
		return cast this;
	}

	@:op(A--) private inline function postDecrement():Int512 {
		var ret = this;
		preDecrement();
		return ret;
	}

	/**
		Returns the sum of `a` and `b`.
	**/
	@:op(A + B) public static inline function add(a:Int512, b:Int512):Int512 {
		var high = a.high + b.high;
		var low = a.low + b.low;
		if (Int256.ucompare(low, a.low) < 0)
			high++;
		return make(high, low);
	}

	/**
		Returns `a` minus `b`.
	**/
	@:op(A - B) public static inline function sub(a:Int512, b:Int512):Int512 {
		var high = a.high - b.high;
		var low = a.low - b.low;
		if (Int256.ucompare(a.low, b.low) < 0)
			high--;
		return make(high, low);
	}

	/**
		Returns the product of `a` and `b`.
	**/
	@:op(A * B)
	public static #if !lua inline #end function mul(a:Int512, b:Int512):Int512 {
		var mask = Int256Helper.maxValue128U;
		var aLow = a.low & mask, aHigh = a.low >>> 128;
		var bLow = b.low & mask, bHigh = b.low >>> 128;
		var part00 = aLow * bLow;
		var part10 = aHigh * bLow;
		var part01 = aLow * bHigh;
		var part11 = aHigh * bHigh;
		var low = part00;
		var high = part11 + (part01 >>> 128) + (part10 >>> 128);
		part01 <<= 128;
		low += part01;
		if (Int256.ucompare(low, part01) < 0)
			high++;
		part10 <<= 128;
		low += part10;
		if (Int256.ucompare(low, part10) < 0)
			high++;
		high += a.low * b.high + a.high * b.low;
		return make(high, low);
	}

	/**
		Returns the quotient of `a` divided by `b`.
	**/
	@:op(A / B) public static inline function div(a:Int512, b:Int512):Int512
		return divMod(a, b).quotient;

	/**
		Returns the modulus of `a` divided by `b`.
	**/
	@:op(A % B) public static inline function mod(a:Int512, b:Int512):Int512
		return divMod(a, b).modulus;

	/**
		Returns `true` if `a` is equal to `b`.
	**/
	@:op(A == B) public static inline function eq(a:Int512, b:Int512):Bool
		return a.high == b.high && a.low == b.low;

	/**
		Returns `true` if `a` is not equal to `b`.
	**/
	@:op(A != B) public static inline function neq(a:Int512, b:Int512):Bool
		return a.high != b.high || a.low != b.low;

	@:op(A < B) private static inline function lt(a:Int512, b:Int512):Bool
		return compare(a, b) < 0;

	@:op(A <= B) private static inline function lte(a:Int512, b:Int512):Bool
		return compare(a, b) <= 0;

	@:op(A > B) private static inline function gt(a:Int512, b:Int512):Bool
		return compare(a, b) > 0;

	@:op(A >= B) private static inline function gte(a:Int512, b:Int512):Bool
		return compare(a, b) >= 0;

	/**
		Returns the bitwise NOT of `a`.
	**/
	@:op(~A) private static inline function complement(a:Int512):Int512
		return make(~a.high, ~a.low);

	/**
		Returns the bitwise AND of `a` and `b`.
	**/
	@:op(A & B) public static inline function and(a:Int512, b:Int512):Int512
		return make(a.high & b.high, a.low & b.low);

	/**
		Returns the bitwise OR of `a` and `b`.
	**/
	@:op(A | B) public static inline function or(a:Int512, b:Int512):Int512
		return make(a.high | b.high, a.low | b.low);

	/**
		Returns the bitwise XOR of `a` and `b`.
	**/
	@:op(A ^ B) public static inline function xor(a:Int512, b:Int512):Int512
		return make(a.high ^ b.high, a.low ^ b.low);

	/**
		Returns `a` left-shifted by `b` bits.
	**/
	@:op(A << B) public static inline function shl(a:Int512, b:Int):Int512 {
		b &= 511;
		return if (b == 0) a.copy() else if (b < 256) make((a.high << b) | (a.low >>> (256 - b)), a.low << b) else make(a.low << (b - 256), 0);
	}

	/**
		Returns `a` right-shifted by `b` bits in signed mode.
		`a` is sign-extended.
	**/
	@:op(A >> B) public static inline function shr(a:Int512, b:Int):Int512 {
		b &= 511;
		return if (b == 0) a.copy() else if (b < 256) make(a.high >> b, (a.high << (256 - b)) | (a.low >>> b)); else make(a.high >> 255, a.high >> (b - 256));
	}

	/**
		Returns `a` right-shifted by `b` bits in unsigned mode.
		`a` is padded with zeroes.
	**/
	@:op(A >>> B) public static inline function ushr(a:Int512, b:Int):Int512 {
		b &= 511;
		return if (b == 0) a.copy() else if (b < 256) make(a.high >>> b, (a.high << (256 - b)) | (a.low >>> b)); else make(0, a.high >>> (b - 256));
	}

	public var high(get, never):Int256;

	private inline function get_high()
		return this.high;

	private inline function set_high(x)
		return this.high = x;

	public var low(get, never):Int256;

	private inline function get_low()
		return this.low;

	private inline function set_low(x)
		return this.low = x;
}

/**
	This typedef will fool `@:coreApi` into thinking that we are using
	the same underlying type, even though it might be different on
	specific platforms.
**/
private typedef __Int512 = ___Int512;

private class ___Int512 {
	public var high:Int256;
	public var low:Int256;

	public inline function new(high, low) {
		this.high = high;
		this.low = low;
	}

	/**
		We also define toString here to ensure we always get a pretty string
		when tracing or calling `Std.string`. This tends not to happen when
		`toString` is only in the abstract.
	**/
	public function toString():String
		return Int512.toStr(cast this);
}
