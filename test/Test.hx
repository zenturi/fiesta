

import fiesta.native.sdl.SDLApplication;
import fiesta.ui.events.*;

class Test {
    public static function main(){
        KeyEvent.callback = function(event:KeyEvent){
            trace(event.eventType);
        };
        
        var app = new SDLApplication();

        app.exec();
    } 
}