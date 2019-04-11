// Copyright (c) 2019 Zenturi Software Co.
// 
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

package fiesta.app;

class Application {

    public static var callback:Application->Void;
    

    public function exec():Int{
        return 0;
    }

    public function init(){}

    public function setFrameRate (frameRate:Float){}


    public function update():Bool{
        return false;
    }



    public static function createApplication(){}




}