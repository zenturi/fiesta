package fiesta.math;
// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT



class Rectangle {
    public var x:Float;
    public var y:Float;
    public var width:Int;
    public var height:Int;

    public function new(x:Float, y:Float, width:Int, height:Int){
        setTo(x, y, width, height);
    }

    public function contract(x:Float, y:Float, width:Int, height:Int){
        if (this.width == 0 && this.height == 0) {

			return;

		}

		if (this.x < x) this.x = x;
		if (this.y < y) this.y = y;
		if (this.x + this.width > x + width) this.width = Std.int(x + width - this.x);
		if (this.y + this.height > y + height) this.height = Std.int(y + height - this.y);
    }

    public function setTo(x:Float, y:Float, width:Int, height:Int){
        this.height = height;
		this.width = width;
		this.x = x;
		this.y = y;
    }

}