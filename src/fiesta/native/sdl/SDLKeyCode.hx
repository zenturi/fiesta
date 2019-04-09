package fiesta.native.sdl;

import sdl.SDL;

import cpp.Int32;

class SDLKeyCode {
    public static function fromScanCode(scanCode:SDLScancode):SDLKeycode {
        return SDL.getKeyFromScancode(scanCode);
    }

    public static function toScanCode(keyCode:SDLKeycode):SDLScancode {
        return SDL.getScancodeFromKey(keyCode);
    }
}