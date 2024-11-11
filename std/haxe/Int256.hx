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

using haxe.Int256;

/**
	A cross-platform signed 256-bit integer.
	Int256 instances can be created from two 128-bit words using `Int256.make()`.
	NOTE: This class is a beta.
**/
#if flash
@:notNull
#end
@:transitive
abstract Int256(__Int256) from __Int256 to __Int256 {
	private inline function new(x:__Int256)
		this = x;

	/**
		Makes a copy of `this` Int256.
	**/
	public inline function copy():Int256
		return Int256.make(high, low);

	/**
		Construct an Int256 from two 128-bit words `high` and `low`.
	**/
	public static function make(high:Int128, low:Int128):Int256
		return new Int256(new __Int256(high, low));

	/**
		Returns an Int256 with the value of the Int `x`.
		`x` is sign-extended to fill 256 bits.
	**/
	@:from public static function ofInt(x:Int):Int256
		#if lua return make((x : Int32) >> 31, (x : Int32)); #else return make(x >> 31, x); #end

	/**
		Returns an Int256 with the value of the Int64 `x`.
		`x` is sign-extended to fill 256 bits.
	**/
	@:from public static function ofInt64(x:Int64):Int256
		#if lua return make((x : Int64) >> 63, (x : Int64)); #else return make(x >> 63, x); #end

	/**
		Returns an Int256 with the value of the 128 `x`.
		`x` is sign-extended to fill 256 bits.
	**/
	@:from public static function ofInt128(x:Int128):Int256
		#if lua return make((x : Int128) >> 127, (x : Int128)); #else return make(x >> 127, x); #end

	/**
		Returns an Int with the value of the Int256 `x`.
		Throws an exception  if `x` cannot be represented in 32 bits.
	**/
	public static function toInt(x:Int256):Int {
		return Int128.toInt(x.low);
	}

	/**
		Returns an Int with the value of the Int256 `x`.
		Throws an exception  if `x` cannot be represented in 64 bits.
	**/
	public static function toInt64(x:Int256):Int64 {
		return Int128.toInt64(x.low);
	}

	/**
		Returns an Int64 with the value of the Int256 `x`.
		Throws an exception  if `x` cannot be represented in 128 bits.
	**/
	public static function toInt128(x:Int256):Int128 {
		var res:Int128 = x.low;

		// This is a completely different and overflow check because we're using Int256's.
		// It can only be triggered if you input an Int256 as the function parameter.
		if ((!isNeg(x) && Int256.isNeg(res)) || (x.high != x.low >> 127))
			throw "Overflow";

		return res.copy();
	}

	@:deprecated('haxe.Int256.is() is deprecated. Use haxe.Int256.isInt256() instead')
	inline public static function is(val:Dynamic):Bool {
		return isInt256(val);
	}

	/**
		Returns whether the value `val` is of type `haxe.Int256`
	**/
	inline public static function isInt256(val:Dynamic):Bool
		return Std.isOfType(val, __Int256);

	/**
		Returns `true` if `x` is less than zero.
	**/
	public static function isNeg(x:Int256):Bool
		return x.high < 0 && x.high.high < 0;

	/**
		Returns `true` if `x` is exactly zero.
	**/
	public static function isZero(x:Int256):Bool
		return x == 0;

	/**
		Compares `a` and `b` in signed mode.
		Returns a negative value if `a < b`, positive if `a > b`,
		or 0 if `a == b`.
	**/
	public static function compare(a:Int256, b:Int256):Int128 {
		var v = a.high - b.high;
		v = if (v != 0) v else Int128.ucompare(a.low, b.low);
		return a.high < 0 ? (b.high < 0 ? v : -1) : (b.high >= 0 ? v : 1);
	}

	/**
		Compares `a` and `b` in unsigned mode.
		Returns a negative value if `a < b`, positive if `a > b`,
		or 0 if `a == b`.
	**/
	public static function ucompare(a:Int256, b:Int256):Int128 {
		var v = Int128.ucompare(a.high, b.high);
		return if (v != 0) v else Int128.ucompare(a.low, b.low);
	}

	/**
		Returns a signed decimal `String` representation of `x`.
	**/
	public static function toStr(x:Int256):String
		return x.toString();

	function toString():String {
		var i:Int256 = cast this;
		if (i == 0)
			return "0";
		var str = "";
		var neg = false;
		if (i.isNeg()) {
			neg = true;
		}
		var ten:Int64 = 10;
		while (i != 0) {
			var r = i.divMod(ten);
			if (r.modulus.isNeg()) {
				str = Int256.neg(r.modulus).low + str;
				i = Int256.neg(r.quotient);
			} else {
				str = r.modulus.low + str;
				i = r.quotient;
			}
		}
		if (neg)
			str = "-" + str;
		return str;
	}

	public static function parseString(sParam:String):Int256 {
		return Int256Helper.parseString(sParam);
	}

	public static function fromFloat(f:Float):Int256 {
		return Int256Helper.fromFloat(f);
	}

	/**
		Performs signed integer divison of `dividend` by `divisor`.
		Returns `{ quotient : Int256, modulus : Int256 }`.
	**/
	public static function divMod(dividend:Int256, divisor:Int256):{quotient:Int256, modulus:Int256} {
		// Handle special cases of 0 and 1
		if (divisor.high == 0) {
			switch (toInt(divisor)) {
				case 0:
					throw "divide by zero";
				case 1:
					return {quotient: dividend.copy(), modulus: 0};
			}
		}

		var divSign = dividend.isNeg() != divisor.isNeg();

		var modulus = dividend.isNeg() ? -dividend : dividend.copy();
		divisor = divisor.isNeg() ? -divisor : divisor;

		var quotient:Int256 = 0;
		var mask:Int256 = 1;

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
	@:op(-A) public static function neg(x:Int256):Int256 {
		var high = ~x.high;
		var low = -x.low;
		if (low == 0)
			high++;
		return make(high, low);
	}

	@:op(++A) private inline function preIncrement():Int256 {
		this = copy();
		this.low++;
		if (this.low == 0)
			this.high++;
		return cast this;
	}

	@:op(A++) private inline function postIncrement():Int256 {
		var ret = this;
		preIncrement();
		return ret;
	}

	@:op(--A) private inline function preDecrement():Int256 {
		this = copy();
		if (this.low == 0)
			this.high--;
		this.low--;
		return cast this;
	}

	@:op(A--) private inline function postDecrement():Int256 {
		var ret = this;
		preDecrement();
		return ret;
	}

	/**
		Returns the sum of `a` and `b`.
	**/
	@:op(A + B) public static function add(a:Int256, b:Int256):Int256 {
		var high = a.high + b.high;
		var low = a.low + b.low;
		if (Int128.ucompare(low, a.low) < 0)
			high++;
		return make(high, low);
	}

	@:op(A + B) public static inline function addInt(a:Int256, b:Int):Int256
		return add(a, b);

	@:op(A + B) public static inline function addInt64(a:Int256, b:Int64):Int256
		return add(a, b);

	@:op(A + B) public static inline function addInt128(a:Int256, b:Int128):Int256
		return add(a, b);

	@:op(A + B) public static inline function intAdd(a:Int, b:Int256):Int256
		return add(a, b);

	@:op(A + B) public static inline function int64Add(a:Int64, b:Int256):Int256
		return add(a, b);

	@:op(A + B) public static inline function int128Add(a:Int128, b:Int256):Int256
		return add(a, b);

	/**
		Returns `a` minus `b`.
	**/
	@:op(A - B) public static function sub(a:Int256, b:Int256):Int256 {
		var high = a.high - b.high;
		var low = a.low - b.low;
		if (Int128.ucompare(a.low, b.low) < 0)
			high--;
		return make(high, low);
	}

	@:op(A - B) public static inline function subInt(a:Int256, b:Int):Int256
		return sub(a, b);

	@:op(A - B) public static inline function subInt64(a:Int256, b:Int64):Int256
		return sub(a, b);

	@:op(A - B) public static inline function subInt128(a:Int256, b:Int128):Int256
		return sub(a, b);

	@:op(A - B) public static inline function intSub(a:Int, b:Int256):Int256
		return sub(a, b);

	@:op(A - B) public static inline function int64Sub(a:Int64, b:Int256):Int256
		return sub(a, b);

	@:op(A - B) public static inline function int128Sub(a:Int128, b:Int256):Int256
		return sub(a, b);

	/**
		Returns the product of `a` and `b`.
	**/
	@:op(A * B)
	public static function mul(a:Int256, b:Int256):Int256 {
		var mask = Int128Helper.maxValue64U;
		var aLow = a.low & mask, aHigh = a.low >>> 64;
		var bLow = b.low & mask, bHigh = b.low >>> 64;
		var part00 = aLow * bLow;
		var part10 = aHigh * bLow;
		var part01 = aLow * bHigh;
		var part11 = aHigh * bHigh;
		var low = part00;
		var high = part11 + (part01 >>> 64) + (part10 >>> 64);
		part01 <<= 64;
		low += part01;
		if (Int128.ucompare(low, part01) < 0)
			high++;
		part10 <<= 64;
		low += part10;
		if (Int128.ucompare(low, part10) < 0)
			high++;
		high += a.low * b.high + a.high * b.low;
		return make(high, low);
	}

	@:op(A * B) public static inline function mulInt(a:Int256, b:Int):Int256
		return mul(a, b);

	@:op(A * B) public static inline function mulInt64(a:Int256, b:Int64):Int256
		return mul(a, b);

	@:op(A * B) public static inline function mulInt128(a:Int256, b:Int128):Int256
		return mul(a, b);

	@:op(A * B) public static inline function intMul(a:Int, b:Int256):Int256
		return mul(a, b);

	@:op(A * B) public static inline function int64Mul(a:Int64, b:Int256):Int256
		return mul(a, b);

	@:op(A * B) public static inline function int128Mul(a:Int128, b:Int256):Int256
		return mul(a, b);

	/**
		Returns the quotient of `a` divided by `b`.
	**/
	@:op(A / B) public static function div(a:Int256, b:Int256):Int256
		return divMod(a, b).quotient;

	@:op(A / B) public static inline function divInt(a:Int256, b:Int):Int256
		return div(a, b);

	@:op(A / B) public static inline function divInt64(a:Int256, b:Int64):Int256
		return div(a, b);

	@:op(A / B) public static inline function divInt128(a:Int256, b:Int128):Int256
		return div(a, b);

	@:op(A / B) public static inline function intDiv(a:Int, b:Int256):Int256
		return div(a, b);

	@:op(A / B) public static inline function int64Div(a:Int64, b:Int256):Int256
		return div(a, b);

	@:op(A / B) public static inline function int128Div(a:Int128, b:Int256):Int256
		return div(a, b);

	/**
		Returns the modulus of `a` divided by `b`.
	**/
	@:op(A % B) public static function mod(a:Int256, b:Int256):Int256
		return divMod(a, b).modulus;

	@:op(A % B) public static inline function modInt(a:Int256, b:Int):Int256
		return mod(a, b);

	@:op(A % B) public static inline function modInt64(a:Int256, b:Int64):Int256
		return mod(a, b);

	@:op(A % B) public static inline function modInt128(a:Int256, b:Int128):Int256
		return mod(a, b);

	@:op(A % B) public static inline function intMod(a:Int, b:Int256):Int256
		return mod(a, b);

	@:op(A % B) public static inline function int64Mod(a:Int64, b:Int256):Int256
		return mod(a, b);

	@:op(A % B) public static inline function int128Mod(a:Int128, b:Int256):Int256
		return mod(a, b);

	/**
		Returns `true` if `a` is equal to `b`.
	**/
	@:op(A == B) public static function eq(a:Int256, b:Int256):Bool
		return a.high == b.high && a.low == b.low;

	@:op(A == B) private static inline function eqInt(a:Int256, b:Int):Bool
		return eq(a, b);

	@:op(A == B) private static inline function eqInt64(a:Int256, b:Int64):Bool
		return eq(a, b);

	@:op(A == B) private static inline function eqInt128(a:Int256, b:Int128):Bool
		return eq(a, b);

	/**
		Returns `true` if `a` is not equal to `b`.
	**/
	@:op(A != B) public static function neq(a:Int256, b:Int256):Bool
		return a.high != b.high || a.low != b.low;

	@:op(A != B) private static inline function neqInt(a:Int256, b:Int):Bool
		return neq(a, b);

	@:op(A != B) private static inline function neqInt64(a:Int256, b:Int64):Bool
		return neq(a, b);

	@:op(A != B) private static inline function neqInt128(a:Int256, b:Int128):Bool
		return neq(a, b);

	@:op(A < B) private static function lt(a:Int256, b:Int256):Bool
		return compare(a, b) < 0;

	@:op(A < B) private static inline function ltInt(a:Int256, b:Int):Bool
		return lt(a, b);

	@:op(A < B) private static inline function ltInt64(a:Int256, b:Int64):Bool
		return lt(a, b);

	@:op(A < B) private static inline function ltInt128(a:Int256, b:Int128):Bool
		return lt(a, b);

	@:op(A <= B) private static function lte(a:Int256, b:Int256):Bool
		return compare(a, b) <= 0;

	@:op(A <= B) private static inline function lteInt(a:Int256, b:Int):Bool
		return lte(a, b);

	@:op(A <= B) private static inline function lteInt64(a:Int256, b:Int64):Bool
		return lte(a, b);

	@:op(A <= B) private static inline function lteInt128(a:Int256, b:Int128):Bool
		return lte(a, b);

	@:op(A > B) private static function gt(a:Int256, b:Int256):Bool
		return compare(a, b) > 0;

	@:op(A > B) private static inline function gtInt(a:Int256, b:Int):Bool
		return gt(a, b);

	@:op(A > B) private static inline function gtInt64(a:Int256, b:Int64):Bool
		return gt(a, b);

	@:op(A > B) private static inline function gtInt128(a:Int256, b:Int128):Bool
		return gt(a, b);

	@:op(A >= B) private static function gte(a:Int256, b:Int256):Bool
		return compare(a, b) >= 0;

	@:op(A >= B) private static inline function gteInt(a:Int256, b:Int):Bool
		return gte(a, b);

	@:op(A >= B) private static inline function gteInt64(a:Int256, b:Int64):Bool
		return gte(a, b);

	@:op(A >= B) private static inline function gteInt128(a:Int256, b:Int128):Bool
		return gte(a, b);

	/**
		Returns the bitwise NOT of `a`.
	**/
	@:op(~A) private static function complement(a:Int256):Int256
		return make(~a.high, ~a.low);

	/**
		Returns the bitwise AND of `a` and `b`.
	**/
	@:op(A & B) public static function and(a:Int256, b:Int256):Int256
		return make(a.high & b.high, a.low & b.low);

	/**
		Returns the bitwise OR of `a` and `b`.
	**/
	@:op(A | B) public static function or(a:Int256, b:Int256):Int256
		return make(a.high | b.high, a.low | b.low);

	/**
		Returns the bitwise XOR of `a` and `b`.
	**/
	@:op(A ^ B) public static function xor(a:Int256, b:Int256):Int256
		return make(a.high ^ b.high, a.low ^ b.low);

	/**
		Returns `a` left-shifted by `b` bits.
	**/
	@:op(A << B) public static function shl(a:Int256, b:Int):Int256 {
		b &= 255;
		return if (b == 0) a.copy() else if (b < 128) make((a.high << b) | (a.low >>> (128 - b)), a.low << b) else make(a.low << (b - 128), 0);
	}

	/**
		Returns `a` right-shifted by `b` bits in signed mode.
		`a` is sign-extended.
	**/
	@:op(A >> B) public static function shr(a:Int256, b:Int):Int256 {
		b &= 255;
		return if (b == 0) a.copy() else if (b < 128) make(a.high >> b, (a.high << (128 - b)) | (a.low >>> b)); else make(a.high >> 127, a.high >> (b - 128));
	}

	/**
		Returns `a` right-shifted by `b` bits in unsigned mode.
		`a` is padded with zeroes.
	**/
	@:op(A >>> B) public static function ushr(a:Int256, b:Int):Int256 {
		b &= 255;
		return if (b == 0) a.copy() else if (b < 128) make(a.high >>> b, (a.high << (128 - b)) | (a.low >>> b)); else make(0, a.high >>> (b - 128));
	}

	public var high(get, never):Int128;

	private inline function get_high()
		return this.high;

	private inline function set_high(x)
		return this.high = x;

	public var low(get, never):Int128;

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
private typedef __Int256 = ___Int256;

private class ___Int256 {
	public var high:Int128;
	public var low:Int128;

	public inline function new(high, low) {
		this.high = high;
		this.low = low;
	}

	/**
		We also define toString here to ensure we always get a pretty string
		when tracing or calling `Std.string`. This tends not to happen when
		`toString` is only in the abstract.
	**/
	public inline function toString():String
		return Int256.toStr(this);
}
