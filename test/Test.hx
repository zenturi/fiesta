

import fiesta.native.sdl.SDLApplication;
import fiesta.ui.events.*;
import fiesta.graphics.events.RenderEvent;
import fiesta.app.events.ApplicationEvent;
import fiesta.native.sdl.SDLWindow;
import sdl.SDL;

class Test {

    // static var state : { window:Window, renderer:Renderer };
    public static function main(){
        
        var app = new SDLApplication();
        ApplicationEvent.callback = function (event:ApplicationEvent) {
            trace(event.eventType);
        }

        WindowEvent.callback = function (event:WindowEvent) {
            trace(event.eventType);
            switch(event.eventType){
                case WINDOW_CLOSE: {
                    Sys.exit(app.quit());
                }
                case _:
            }
        }

        RenderEvent.callback = function (event:RenderEvent){
            trace(event.eventType);
            // SDL.setRenderDrawColor(state.renderer, 0, 0, 0, 0);
            // SDL.renderClear(state.renderer);
            // SDL.renderPresent(state.renderer);
        }
        KeyEvent.callback = function(event:KeyEvent){
            trace(event.eventType);
        };

        MouseEvent.callback = function(event:MouseEvent){
            trace(event.eventType);
        };
        
        var window = new SDLWindow(app, 600, 600, SDL_WINDOW_RESIZABLE, "My App");
        app.exec();

        
    } 
}