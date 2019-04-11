package fiesta.graphics;
// Copyright (c) 2019 Zenturi Software Co.
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import haxe.io.BytesData;

import fiesta.graphics.data.*;

class ImageBuffer {
	public var width:Int;
	public var height:Int;
	public var bitsPerPixel:Int;
	public var format:PixelFormat;
	public var data:ArrayBufferView;
	public var premultiplied:Bool;
	public var transparent:Bool;

	public function new() {
		width = 0;
		height = 0;
		bitsPerPixel = 32;
		format = RGBA32;
		data = new ArrayBufferView(0);
		premultiplied = false;
		transparent = false;
	}

    public function blit(src:Bytes, x:Int, y:Int, width:Int, height:Int){
        if (x < 0 || x + width > this.width || y < 0 || y + height > this.height) {

			return;

		}

        var stride = stride();

        for(i in 0...height){
            this.data.buffer.blit((i + y) * this.width + x, src, i * width, stride);
        }

        
    }

    public function resize(width:Int, height:Int, bitsPerPixel:Int){
        this.bitsPerPixel = bitsPerPixel;
		this.width = width;
		this.height = height;

        var stride = stride();

        if(data != null){
            this.data.resize(height * stride);
        }
    }

    public function stride ():Int {
		return width * (((bitsPerPixel + 3) & ~0x3) >> 3);
	}
}



