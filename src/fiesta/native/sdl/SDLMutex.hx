package fiesta.native.sdl;

import sdl.SDL;
import sdl.Thread.Mutex;

class SDLMutex {
    private var mutex:Mutex;
    public function new(){
        mutex = SDL.CreateMutex();
    }

    public function lock():Bool {
        if(mutex != null){
            return SDL.LockMutex(mutex) == 0;
        }
        return false;
    }

    public function tryLock():Bool {
         if(mutex != null){
            return SDL.TryLockMutex(mutex) == 0;
        }
        return false;
    }

    public function unlock():Bool {
         if(mutex != null){
            return SDL.UnlockMutex(mutex) == 0;
        }
        return false;
    }
}