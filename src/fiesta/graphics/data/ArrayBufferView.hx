package fiesta.graphics.data;
import haxe.io.ArrayBufferView.ArrayBufferViewData;
import haxe.io.Error;


typedef ArrayBufferViewData = ArrayBufferViewImpl;

class ArrayBufferViewImpl {
	public var bytes : Bytes;
	public var byteOffset : Int;
	public var byteLength : Int;
	public function new(bytes, pos, length) {
		this.bytes = bytes;
		this.byteOffset = pos;
		this.byteLength = length;
	}
	public function sub( begin : Int, ?length : Int ) {
		if( length == null ) length = byteLength - begin;
		if( begin < 0 || length < 0 || begin + length > byteLength ) throw Error.OutsideBounds;
		return new ArrayBufferViewImpl(bytes, byteOffset + begin, length);
	}
	public function subarray( ?begin : Int, ?end : Int ) {
		if( begin == null ) begin = 0;
		if( end == null ) end = byteLength - begin;
		return sub(begin, end - begin);
	}
}

abstract ArrayBufferView(ArrayBufferViewData) {

	public var buffer(get,never) : Bytes;
	public var byteOffset(get, never) : Int;
	public var byteLength(get, set) : Int;

	public inline function new( size : Int ) {
		this = new ArrayBufferViewData( new Bytes(size), 0, size);
	}

	inline function get_byteOffset() : Int return this.byteOffset;
	inline function get_byteLength() : Int return this.byteLength;

    inline function set_byteLength(length:Int) : Int return this.byteLength;
	inline function get_buffer() : Bytes return this.bytes;

	public inline function sub( begin : Int, ?length : Int ) : ArrayBufferView {
		return fromData(this.sub(begin,length));
	}

	public inline function subarray( ?begin : Int, ?end : Int ) : ArrayBufferView {
		return fromData(this.subarray(begin,end));
	}

	public inline function getData() : ArrayBufferViewData {
		return this;
	}

	public static inline function fromData( a : ArrayBufferViewData ) : ArrayBufferView {
		return cast a;
	}

	public static function fromBytes( bytes : Bytes, pos = 0, ?length : Int ) : ArrayBufferView {
		if( length == null ) length = bytes.length - pos;
		if( pos < 0 || length < 0 || pos + length > bytes.length ) throw Error.OutsideBounds;
		return fromData(new ArrayBufferViewData(bytes, pos, length));
	}


    public inline function resize(size:Int){
        buffer.resize(size);
        byteLength = size;
    }

}