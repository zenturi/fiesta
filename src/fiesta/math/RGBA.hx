package fiesta.math;

using thx.Arrays;
using thx.Floats;
using thx.Ints;
using thx.Functions;
using thx.Strings;

import thx.color.*;
import haxe.io.*;
import fiesta.graphics.PixelFormat;

/**
	A version of `RGB` with an additional channel for `alpha`.

	`RGBA` uses an `Int` as the underlying type.
**/
abstract RGBA(Int) from Int {
	private static var __alpha16:UInt32Array;
	private static var __clamp:UInt8Array;
	private static var a16:Int;
	private static var unmult:Float;

	private static function __init__():Void {
		__alpha16 = new UInt32Array(256);

		for (i in 0...256) {
			__alpha16[i] = Math.ceil((i) * ((1 << 16) / 0xFF));
		}

		__clamp = new UInt8Array(0xFF + 0xFF + 1);

		for (i in 0...0xFF) {
			__clamp[i] = i;
		}

		for (i in 0xFF...(0xFF + 0xFF + 1)) {
			__clamp[i] = 0xFF;
		}
	}

	inline public static function create(red:Int, green:Int, blue:Int, alpha:Int):RGBA
		return ((red & 0xFF) << 24) | ((green & 0xFF) << 16) | ((blue & 0xFF) << 8) | ((alpha & 0xFF) << 0);

	@:from public static function fromFloats(arr:Array<Float>):RGBA {
		var ints = arr.resized(4).map.fn((_ * 255).round());
		return create(ints[0], ints[1], ints[2], ints[3]);
	}

	@:from public static function fromInt(RGBA:Int):RGBA
		return RGBA;

	@:from public static function fromInts(arr:Array<Int>):RGBA {
		arr = arr.resized(4);
		return create(arr[0], arr[1], arr[2], arr[3]);
	}

	@:from public static function fromString(color:String):Null<RGBA> {
		var info = ColorParser.parseHex(color);
		if (null == info)
			info = ColorParser.parseColor(color);
		if (null == info)
			return null;

		return try switch info.name {
			case 'RGB':
				RGB.fromInts(ColorParser.getInt8Channels(info.channels, 3)).toRgba();
			case 'RGBA':
				RGBA.create(ColorParser.getInt8Channel(info.channels[0]), ColorParser.getInt8Channel(info.channels[1]),
					ColorParser.getInt8Channel(info.channels[2]), Math.round(ColorParser.getFloatChannel(info.channels[3], NaturalMode) * 255));
			case 'hexa':
				RGBA.create(ColorParser.getInt8Channel(info.channels[0]), ColorParser.getInt8Channel(info.channels[1]),
					ColorParser.getInt8Channel(info.channels[2]), ColorParser.getInt8Channel(info.channels[3]));
			case _:
				null;
		} catch (e:Dynamic) null;
	}

	inline public function new(RGBA:Int):RGBA
		this = RGBA;

	public var red(get, never):Int;
	public var green(get, never):Int;
	public var blue(get, never):Int;
	public var alpha(get, never):Int;

	public function combineColor(other:RGB):RGB {
		var a = alpha / 255;
		return RGB.fromInts([
			Math.round((1 - a) * other.red + a * red),
			Math.round((1 - a) * other.green + a * green),
			Math.round((1 - a) * other.blue + a * blue)
		]);
	}

	/**
		Multiplies the red, green and blue components by the current alpha component
	**/
	public inline function multiplyAlpha() {
		if (alpha == 0) {
			if (this != 0) {
				this = 0;
			}
		} else if (alpha != 0xFF) {
			RGBA.a16 = RGBA.__alpha16[a];
			this = RGBA.create((red * a16) >> 16, (green * a16) >> 16, (blue * a16) >> 16, alpha);
		}
	}

	/**
		Divides the current red, green and blue components by the alpha component
	**/
	public inline function unmultiplyAlpha() {
		if (alpha != 0 && alpha != 0xFF) {
			RGBA.unmult = 255.0 / a;
			this = RGBA.create(RGBA.__clamp[Math.round(red * unmult)], RGBA.__clamp[Math.round(green * unmult)], RGBA.__clamp[Math.round(blue * unmult)], alpha);
		}
	}

	/**
		Reads a value from a `UInt8Array` into the current `RGBA` color
		@param	data	A `UInt8Array` instance
		@param	offset	An offset into the `UInt8Array` to read
		@param	format	(Optional) The `PixelFormat` represented by the `UInt8Array` data
		@param	premultiplied	(Optional) Whether the data is stored in premultiplied alpha format
	**/
	public inline function readUInt8(data:UInt8Array, offset:Int, format:PixelFormat = RGBA32, premultiplied:Bool = false):Void
	{
		switch (format)
		{
			case BGRA32:
				this = RGBA.create(data[offset + 2], data[offset + 1], data[offset], data[offset + 3]);

			case RGBA32:
				this = RGBA.create(data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);

			case ARGB32:
				this = RGBA.create(data[offset + 1], data[offset + 2], data[offset + 3], data[offset]);
		}

		if (premultiplied)
		{
			unmultiplyAlpha();
		}
	}

	/**
		Writes the current `RGBA` color into a `UInt8Array`
		@param	data	A `UInt8Array` instance
		@param	offset	An offset into the `UInt8Array` to write
		@param	format	(Optional) The `PixelFormat` represented by the `UInt8Array` data
		@param	premultiplied	(Optional) Whether the data is stored in premultiplied alpha format
	**/
	public inline function writeUInt8(data:UInt8Array, offset:Int, format:PixelFormat = RGBA32, premultiplied:Bool = false):Void {
		if (premultiplied) {
			multiplyAlpha();
		}

		switch (format) {
			case BGRA32:
				data[offset] = blue;
				data[offset + 1] = g;
				data[offset + 2] = r;
				data[offset + 3] = a;

			case RGBA32:
				data[offset] = red;
				data[offset + 1] = green;
				data[offset + 2] = blue;
				data[offset + 3] = alpha;

			case ARGB32:
				data[offset] = alpha;
				data[offset + 1] = red;
				data[offset + 2] = green;
				data[offset + 3] = blue;
		}
	}

	public function darker(t:Float):RGBA
		return toRgbxa().darker(t).toRgba();

	public function lighter(t:Float):RGBA
		return toRgbxa().lighter(t).toRgba();

	public function transparent(t:Float):RGBA
		return toRgbxa().transparent(t).toRgba();

	public function opaque(t:Float)
		return toRgbxa().opaque(t).toRgba();

	public function interpolate(other:RGBA, t:Float)
		return toRgbxa().interpolate(other.toRgbxa(), t).toRgba();

	public function withAlpha(newalpha:Int)
		return RGBA.fromInts([red, green, blue, newalpha]);

	public function withAlphaf(newalpha:Float)
		return RGBA.fromInts([red, green, blue, Math.round(255 * newalpha)]);

	public function withRed(newred:Int)
		return RGBA.fromInts([newred, green, blue, alpha]);

	public function withGreen(newgreen:Int)
		return RGBA.fromInts([red, newgreen, blue, alpha]);

	public function withBlue(newblue:Int)
		return RGBA.fromInts([red, green, newblue, alpha]);

	@:to public function toHsla():Hsla
		return toRgbxa().toHsla();

	@:to public function toHsva():Hsva
		return toRgbxa().toHsva();

	@:to public function toRgb():RGB
		return RGB.create(red, green, blue);

	@:to public function toArgb():Argb
		return Argb.create(alpha, red, green, blue);

	@:to public function toRgbx():Rgbx
		return Rgbx.fromInts([red, green, blue]);

	@:to public function toRgbxa():Rgbxa
		return Rgbxa.fromInts([red, green, blue, alpha]);

	public function toCss3():String
		return 'RGBA($red,$green,$blue,${alpha / 255})';

	@:to public function toString():String
		return toCss3();

	public function toHex(prefix = "#")
		return '$prefix${red.hex(2)}${green.hex(2)}${blue.hex(2)}${alpha.hex(2)}';

	@:op(A == B) public function equals(other:RGBA):Bool
		return red == other.red && alpha == other.alpha && green == other.green && blue == other.blue;

	public function toInt():Int
		return this;

	inline function get_alpha():Int
		return this & 0xFF;

	inline function get_red():Int
		return (this >> 24) & 0xFF;

	inline function get_green():Int
		return (this >> 16) & 0xFF;

	inline function get_blue():Int
		return (this >> 8) & 0xFF;
}
