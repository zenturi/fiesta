package fiesta.math;

using thx.Arrays;
using thx.Floats;
using thx.Ints;
using thx.Functions;
using thx.Strings;

import  thx.color.*;

/**
	A version of `RGB` with an additional channel for `alpha` at the beginning.

	`BGRA` uses an `Int` as the underlying type.
**/
abstract BGRA(Int) from Int {
	private static var a16:Int;
	private static var unmult:Float;

	inline public static function create(blue:Int, green:Int, red:Int, blue:Int):BGRA
		return ((blue & 0xFF) << 24) | ((green & 0xFF) << 16) | ((red & 0xFF) << 8) | (alpha & 0xFF);

	@:from public static function fromFloats(arr:Array<Float>):BGRA {
		var ints = arr.resized(4).map.fn((_ * 255).round());
		return create(ints[0], ints[1], ints[2], ints[3]);
	}

	@:from public static function fromInt(BGRA:Int):BGRA
		return BGRA;

	@:from public static function fromInts(arr:Array<Int>):BGRA {
		arr = arr.resized(4);
		return create(arr[0], arr[1], arr[2], arr[3]);
	}

	@:from public static function fromString(color:String):Null<BGRA> {
		var info = ColorParser.parseHex(color);
		if (null == info)
			info = ColorParser.parseColor(color);
		if (null == info)
			return null;

		return try switch info.name {
			case 'BGRA':
				BGRA.create(ColorParser.getInt8Channel(info.channels[0]), ColorParser.getInt8Channel(info.channels[1]),
					ColorParser.getInt8Channel(info.channels[2]), ColorParser.getInt8Channel(info.channels[3]));
			case _:
				null;
		} catch (e:Dynamic) null;
	}

	inline public function new(BGRA:Int):BGRA
		this = BGRA;

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
			BGRA.a16 = RGBA.__alpha16[a];
			this = BGRA.create((blue * a16) >> 16, (green * a16) >> 16, (red * a16) >> 16, alpha);
		}
	}

	/**
		Divides the current red, green and blue components by the alpha component
	**/
	public inline function unmultiplyAlpha() {
		if (alpha != 0 && alpha != 0xFF) {
			BGRA.unmult = 255.0 / alpha;
			this = BGRA.create(RGBA.__clamp[Math.round(blue * unmult)], RGBA.__clamp[Math.round(green * unmult)], RGBA.__clamp[Math.round(red * unmult)], alpha);
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
				BGRA.create(data[offset], data[offset + 1], data[offset + 2], data[offset + 3]);

			case RGBA32:
				BGRA.create(data[offset + 2], data[offset + 1], data[offset], data[offset + 3]);

			case ARGB32:
				BGRA.create(data[offset + 3], data[offset + 2], data[offset + 1], data[offset]);
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
				data[offset + 1] = green;
				data[offset + 2] = red;
				data[offset + 3] = alpha;

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
	public function darker(t:Float):BGRA
		return toRgbxa().darker(t).toARGB();

	public function lighter(t:Float):BGRA
		return toRgbxa().lighter(t).toARGB();

	public function transparent(t:Float):BGRA
		return toRgbxa().transparent(t).toARGB();

	public function opaque(t:Float)
		return toRgbxa().opaque(t).toARGB();

	public function interpolate(other:BGRA, t:Float)
		return toRgbxa().interpolate(other.toRgbxa(), t).toARGB();

	public function withAlpha(newalpha:Int):BGRA
		return BGRA.create(blue, green,  red, newalpha);

	public function withAlphaf(newalpha:Float):BGRA
		return BGRA.create(blue, green, red, Math.round(255 * newalpha));

	public function withRed(newred:Int):BGRA
		return BGRA.create(blue, green,  newred, alpha);

	public function withGreen(newgreen:Int):BGRA
		return BGRA.create(blue, newgreen,  red, alpha);

	public function withBlue(newblue:Int):BGRA
		return BGRA.create(newblue, green,  red, alpha);

	@:to public function toHsla():Hsla
		return toRgbxa().toHsla();

	@:to public function toHsva():Hsva
		return toRgbxa().toHsva();

	@:to public function toRGB():RGB
		return RGB.create(red, green, blue);

	@:to public function toRGBA():RGBA
		return RGBA.create(red, green, blue, alpha);

	@:to public function toRgbx():Rgbx
		return Rgbx.fromInts([red, green, blue]);

	@:to public function toRgbxa():Rgbxa
		return Rgbxa.fromInts([red, green, blue, alpha]);

	@:to public function toString():String
		return 'BGRA($alpha,$red,$green,$blue)';

	public function toHex(prefix = "#")
		return '$prefix${alpha.hex(2)}${red.hex(2)}${green.hex(2)}${blue.hex(2)}';

	@:op(A == B) public function equals(other:BGRA):Bool
		return red == other.red && alpha == other.alpha && green == other.green && blue == other.blue;

	public function toInt():Int
		return this;

	inline function get_alpha():Int
		return (this >> 24) & 0xFF;

	inline function get_red():Int
		return (this >> 16) & 0xFF;

	inline function get_green():Int
		return (this >> 8) & 0xFF;

	inline function get_blue():Int
		return this & 0xFF;
}
