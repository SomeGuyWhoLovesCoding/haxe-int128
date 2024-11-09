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
	Helper for parsing to `Int512` instances.
**/
class Int512Helper {
	/**
		Create `Int256` from given string.
	**/
	public static function parseString(sParam:String):Int512 {
		var base = Int512.ofInt(10);
		var current = Int512.ofInt(0);
		var multiplier = Int512.ofInt(1);
		var sIsNegative = false;

		var s = StringTools.trim(sParam);
		if (s.charAt(0) == "-") {
			sIsNegative = true;
			s = s.substring(1, s.length);
		}
		var len = s.length;

		for (i in 0...len) {
			var digitInt = s.charCodeAt(len - 1 - i) - '0'.code;

			if (digitInt < 0 || digitInt > 9) {
				throw "NumberFormatError";
			}

			if (digitInt != 0) {
				var digit:Int512 = Int512.ofInt(digitInt);
				if (sIsNegative) {
					current = Int512.sub(current, Int512.mul(multiplier, digit));
					if (!Int512.isNeg(current)) {
						throw "NumberFormatError: Underflow";
					}
				} else {
					current = Int512.add(current, Int512.mul(multiplier, digit));
					if (Int512.isNeg(current)) {
						throw "NumberFormatError: Overflow";
					}
				}
			}

			multiplier = Int512.mul(multiplier, base);
		}
		return current;
	}

	/**
		Create `Int512` from given float.
	**/
	public static function fromFloat(f:Float):Int512 {
		if (Math.isNaN(f) || !Math.isFinite(f)) {
			throw "Number is NaN or Infinite";
		}

		var noFractions = f - (f % 1);

		// 2^53-1 and -2^53+1: these are parseable without loss of precision.
		// In theory 2^53 and -2^53 are parseable too, but then there's no way to
		// distinguish 2^53 from 2^53+1
		// (i.e. trace(9007199254740992. + 1. > 9007199254740992.); // false!)
		if (noFractions > 9007199254740991) {
			throw "Conversion overflow";
		}
		if (noFractions < -9007199254740991) {
			throw "Conversion underflow";
		}

		var result = Int512.ofInt(0);
		var neg = noFractions < 0;
		var rest = neg ? -noFractions : noFractions;

		var i = 0;
		while (rest >= 1) {
			var curr = rest % 2;
			rest = rest / 2;
			if (curr >= 1) {
				result = Int512.add(result, Int512.shl(Int512.ofInt(1), i));
			}
			i++;
		}

		if (neg) {
			result = Int512.neg(result);
		}

		return result;
	}

	/**
		The maximum `Int512` value.
	 */
	public static var maxValue:Int512 = Int512.make(Int256Helper.maxValue, -1);

	/**
		The minimum `Int512` value.
	 */
	public static var minValue:Int512 = ~maxValue;

	/**
		The maximum `Int64` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue64:Int512 = Int512.ofInt64(Int64Helper.maxValue);

	/**
		The minimum `Int64` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var minValue64:Int512 = ~maxValue64;

	/**
		The maximum unsigned `Int64` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue64U:Int512 = Int512.make(1, 0);

	/**
		The maximum `Int128` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue128:Int512 = Int512.ofInt128(Int128Helper.maxValue);

	/**
		The minimum `Int128` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var minValue128:Int512 = ~maxValue128;

	/**
		The maximum unsigned `Int128` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue128U:Int512 = Int256.make(0, -1);

	/**
		The maximum `Int256` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue256:Int512 = Int512.ofInt256(Int256Helper.maxValue);

	/**
		The minimum `Int256` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var minValue256:Int512 = ~maxValue256;

	/**
		The maximum unsigned `Int256` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue256U:Int512 = Int512.make(0, -1);

	/**
		The maximum `Int32` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue32:Int512 = Int512.ofInt256(Int256Helper.maxValue32);

	/**
		The minimum `Int32` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var minValue32:Int512 = ~maxValue32;

	/**
		The maximum unsigned `Int32` value with the type `Int512`.
		This is handy for type comparison.
	 */
	public static var maxValue32U:Int512 = Int64.make(0, -1);
}
