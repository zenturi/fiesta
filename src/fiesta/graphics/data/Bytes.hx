package fiesta.graphics.data;

import haxe.io.BytesData;
class Bytes extends haxe.io.Bytes {
    private var __length:Int;

    public function new(length:Int){
       var  bytes = haxe.io.Bytes.alloc (length);
       super(length, bytes.b);
        __length = length;
    }

   public function resize(size:Int){
        if (size > __length) {

            var bytes = haxe.io.Bytes.alloc ((((size + 1) * 3) >> 1));
            var cacheLength = length;
            length = __length;
            bytes.blit (0, this, 0, __length);
            length = cacheLength;
            setData (bytes);

        }

        if (length < size) {

            length = size;

        }
    }

    private inline function setData(bytes:haxe.io.Bytes){
        b = bytes.b;
        __length = b.length;
    }
}