// Copyright (c) 2019 Zenturi Software Co.
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT
package fiesta.native.sdl;

import cpp.Pointer;
import sdl.SDL.SDL_WindowFlags;
import sdl.Renderer;
import sdl.Texture;
import sdl.SDL;
import fiesta.ui.Cursor;
import fiesta.app.Application;
import fiesta.ui.Window;
import sdl.GLContext;
import opengl.GL;
import opengl.WebGL;
import fiesta.graphics.ImageBuffer;
import fiesta.system.DisplayMode;
import fiesta.graphics.PixelFormat;
import fiesta.math.Rectangle;

@:headerCode('
#if defined (HX_WINDOWS) || defined (HX_MACOS) || defined(HX_LINUX)
#include <GL/glew.h>
#endif
#ifdef HX_WINDOWS
#include <SDL_syswm.h>
#include <Windows.h>
#undef createWindow
#endif

#ifdef NEED_EXTENSIONS
#define DEFINE_EXTENSION
#include "OpenGLExtensions.h"
#undef DEFINE_EXTENSION
#endif
')
class SDLWindow extends Window {
	private static var currentCursor:Cursor;
	private static var displayModeSet = false;

	private var context:Dynamic;
	private var contextHeight:Int;
	private var contextWidth:Int;

	public var sdlTexture:Texture;
	public var sdlRenderer:Renderer;

	static inline function __init__() {
		SDLCursor.arrowCursor = null;
		SDLCursor.crosshairCursor = null;
		SDLCursor.moveCursor = null;
		SDLCursor.pointerCursor = null;
		SDLCursor.resizeNESWCursor = null;
		SDLCursor.resizeNSCursor = null;
		SDLCursor.resizeNWSECursor = null;
		SDLCursor.resizeWECursor = null;
		SDLCursor.textCursor = null;
		SDLCursor.waitCursor = null;
		SDLCursor.waitArrowCursor = null;
	}

	public function new(application:Application, width:Int, height:Int, flags:Int, title:String) {
		sdlTexture = null;
		sdlRenderer = null;
		context = null;

		contextWidth = 0;
		contextHeight = 0;

		currentApplication = application;

		this.flags = flags;

		var sdlWindowFlags:Int = 0;

		if ((flags & WINDOW_FLAG_FULLSCREEN) != 0)
			sdlWindowFlags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
		if ((flags & WINDOW_FLAG_RESIZABLE) != 0) {
			sdlWindowFlags |= SDL_WINDOW_RESIZABLE;
		}
		if ((flags & WINDOW_FLAG_BORDERLESS) != 0)
			sdlWindowFlags |= SDL_WINDOW_BORDERLESS;
		if ((flags & WINDOW_FLAG_HIDDEN) != 0)
			sdlWindowFlags |= SDL_WINDOW_HIDDEN;
		if ((flags & WINDOW_FLAG_MINIMIZED) != 0)
			sdlWindowFlags |= SDL_WINDOW_MINIMIZED;
		if ((flags & WINDOW_FLAG_MAXIMIZED) != 0)
			sdlWindowFlags |= SDL_WINDOW_MAXIMIZED;

		#if emscripten
		if ((flags & WINDOW_FLAG_ALWAYS_ON_TOP) != 0)
			sdlWindowFlags |= SDL_WINDOW_ALWAYS_ON_TOP;
		#end
		#if (windows && NATIVE_TOOLKIT_SDL_ANGLE && !winrt)
		untyped __cpp__('
        // #if defined (HX_WINDOWS) && defined (NATIVE_TOOLKIT_SDL_ANGLE) && !defined (HX_WINRT)
		OSVERSIONINFOEXW osvi = { sizeof (osvi), 0, 0, 0, 0, {0}, 0, 0 };
		DWORDLONG const dwlConditionMask = VerSetConditionMask (VerSetConditionMask (VerSetConditionMask (0, VER_MAJORVERSION, VER_GREATER_EQUAL), VER_MINORVERSION, VER_GREATER_EQUAL), VER_SERVICEPACKMAJOR, VER_GREATER_EQUAL);
		osvi.dwMajorVersion = HIBYTE (_WIN32_WINNT_VISTA);
		osvi.dwMinorVersion = LOBYTE (_WIN32_WINNT_VISTA);
		osvi.wServicePackMajor = 0;

		if (VerifyVersionInfoW (&osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_SERVICEPACKMAJOR, dwlConditionMask) == FALSE) {

			flags &= ~WINDOW_FLAG_HARDWARE;

		}
		#endif

        //#ifndef EMSCRIPTEN
		// SDL_SetHint (SDL_HINT_ANDROID_TRAP_BACK_BUTTON, "0");
		// SDL_SetHint (SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");
		
        int nothing = 0');

		#end

		if ((flags & WINDOW_FLAG_HARDWARE) != 0) {
			sdlWindowFlags |= SDL_WINDOW_OPENGL;

			if ((flags & WINDOW_FLAG_ALLOW_HIGHDPI) != 0) {
				sdlWindowFlags |= SDL_WINDOW_ALLOW_HIGHDPI;
			}

			#if windows
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
			SDL.setHint(SDL_HINT_VIDEO_WIN_D3DCOMPILER, "d3dcompiler_47.dll");
			#end

			#if raspberrypi
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
			SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengles2");
			#end

			#if (ios || tvos || appletv)
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
			#end

			if ((flags & WINDOW_FLAG_DEPTH_BUFFER) != 0) {
				SDL.GL_SetAttribute(SDL_GL_DEPTH_SIZE, (32 - (flags & WINDOW_FLAG_STENCIL_BUFFER) != 0) ? 8 : 0);
			}

			if ((flags & WINDOW_FLAG_STENCIL_BUFFER) != 0) {
				SDL.GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
			}

			if ((flags & WINDOW_FLAG_HW_AA_HIRES) != 0) {
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);
			} else if ((flags & WINDOW_FLAG_HW_AA) != 0) {
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
				SDL.GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 2);
			}

			if ((flags & WINDOW_FLAG_COLOR_DEPTH_32_BIT) != 0) {
				SDL.GL_SetAttribute(SDL_GL_RED_SIZE, 8);
				SDL.GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
				SDL.GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
				SDL.GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
			} else {
				SDL.GL_SetAttribute(SDL_GL_RED_SIZE, 5);
				SDL.GL_SetAttribute(SDL_GL_GREEN_SIZE, 6);
				SDL.GL_SetAttribute(SDL_GL_BLUE_SIZE, 5);
			}
		}

		sdlWindow = SDL.createWindow(title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);

		#if (ios || tvos)
		if (sdlWindow != null && SDL.GL_CreateContext(sdlWindow) != null) {
			SDL.destroyWindow(sdlWindow);
			SDL.GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);

			sdlWindow = SDL.createWindow(title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);
		}
		#end

		if (sdlWindow == null) {
			throw 'Could not create SDL window: ${SDL.getError()}';
		}

		#if (windows && !winrt)
		untyped __cpp__('
        // #if defined (HX_WINDOWS) && !defined (HX_WINRT)

		HINSTANCE handle = .GetModuleHandle (nullptr);
		HICON icon = .LoadIcon (handle, MAKEINTRESOURCE (1));

		if (icon != nullptr) {

			SDL_SysWMinfo wminfo;
			SDL_VERSION (&wminfo.version);

			if (SDL_GetWindowWMInfo (sdlWindow, &wminfo) == 1) {

				HWND hwnd = wminfo.info.win.window;

				#ifdef _WIN64
				.SetClassLongPtr (hwnd, GCLP_HICON, reinterpret_cast<LONG_PTR>(icon));
				#else
				.SetClassLong (hwnd, GCL_HICON, reinterpret_cast<LONG>(icon));
				#endif

			}

		}

		// #endif
        int nothing');

		#end

		var sdlRendererFlags = 0;

		if ((flags & WINDOW_FLAG_HARDWARE) != 0) {
			sdlRendererFlags |= SDL_RENDERER_ACCELERATED;

			context = SDL.GL_CreateContext(sdlWindow);

			if (context != null && SDL.GL_MakeCurrent(sdlWindow, context) == 0) {
				if ((flags & WINDOW_FLAG_VSYNC) != 0) {
					SDL.GL_SetSwapInterval(true);
				} else {
					SDL.GL_SetSwapInterval(false);
				}
				#if (linc_opengl_EGL || linc_opengl_GLES || linc_opengl_GLES1 || linc_opengl_GLES2 || linc_opengl_GLES3)
				var version = 0;
				GL.glGetIntegerv(GL.GL_MAJOR_VERSION, [version]);
				if (version == 0) {
					var versionScan = 0;
					untyped __cpp__('sscanf ((const char*)glGetString (GL_VERSION), "%f", &versionScan)');

					version = versionScan;
				}

				if (version < 2 && Pointer.fromRaw(GL.glGetString(GL.GL_VERSION)).get_ref().toString() == "OpenGL ES") {
					SDL.GL_DeleteContext(context);
					context = null;
				}
				#elseif (ios || tvos)
				GL.glGetIntegerv(GL.GL_FRAMEBUFFER_BINDING, [0]);
				GL.glGetIntegerv(GL.GL_RENDERBUFFER_BINDING, [0]);
				#end
			} else {
				SDL.GL_DeleteContext(context);
				context = null;
			}
		}

		if (context == null) {
			sdlRendererFlags &= ~SDL_RENDERER_ACCELERATED;
			sdlRendererFlags &= ~SDL_RENDERER_PRESENTVSYNC;

			sdlRendererFlags |= SDL_RENDERER_SOFTWARE;

			sdlRenderer = SDL.createRenderer(sdlWindow, -1, sdlRendererFlags);
		}

		if (context != null || sdlRenderer != null) {
			cast(currentApplication, SDLApplication).registerWindow(this);
		} else {
			trace('Could not create SDL renderer: ${SDL.getError()}');
		}
	}

	public function alert(message:String, title:String){
		untyped __cpp__('
		int count = 0;
		int speed = 0;
		bool stopOnForeground = true;

		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		SDL_GetWindowWMInfo (sdlWindow, &info);

		FLASHWINFO fi;
		fi.cbSize = sizeof (FLASHWINFO);
		fi.hwnd = info.info.win.window;
		fi.dwFlags = stopOnForeground ? FLASHW_ALL | FLASHW_TIMERNOFG : FLASHW_ALL | FLASHW_TIMER;
		fi.uCount = count;
		fi.dwTimeout = speed;
		FlashWindowEx (&fi)');

		if (message) {

			SDL.showSimpleMessageBox (SDL_MESSAGEBOX_INFORMATION, title, message, sdlWindow);

		}
	}


	public function close(){
		if (sdlWindow != null) {

			SDL.destroyWindow (sdlWindow);
			sdlWindow = 0;

		}

		if (sdlRenderer) {

			SDL.destroyRenderer (sdlRenderer);

		} else if (context) {

			SDL.GL_DeleteContext (context);
		}

	}


	public function contextFlip(){
		if (context != null && sdlRenderer == null) {

			SDL.GL_SwapWindow (sdlWindow);

		} else if (sdlRenderer) {

			SDL.renderPresent (sdlRenderer);

		}
	}


	public function contextLock(){
		if(sdlRenderer != null){
			var size:SDLSize = {
				w: 0,
				h: 0
			};
			size = SDL.getRendererOutputSize (sdlRenderer, size);

			if (w != contextWidth || h != contextHeight) {
				if (sdlTexture != null) {

					SDL.destroyTexture (sdlTexture);

					sdlTexture = SDL.createTexture (sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, w, h);

					contextHeight = h;
					contextWidth = w;

				}
			}

		}
	}

	public function contextMakeCurrent () {

		if (sdlWindow != null && context != null) {

			SDL.GL_MakeCurrent (sdlWindow, context);

		}

	}


	public function contextUnLock(){
		if (sdlTexture != null) {

			SDL.unlockTexture (sdlTexture);
			SDL.renderClear (sdlRenderer);
			SDL.renderCopy (sdlRenderer, sdlTexture, null, null);

		}
	}


	public function focus(){
		SDL.raiseWindow(sdlWindow);
	}
	

	public function readPixels(buffer:ImageBuffer, rectangle:Rectangle) {
		if (sdlRenderer != null) {
			var bounds:SDLRect {
				x: 0,
				y: 0,
				w: 0,
				h: 0
			};

			if (rect != null) {
				bounds.x = rect.x;
				bounds.y = rect.y;
				bounds.w = rect.width;
				bounds.h = rect.height;
			} else {
				SDL.getWindowSize(sdlWindow, bounds.w, bounds.h);
			}

			buffer.resize(bounds.w, bounds.h, 32);

			SDL.renderReadPixels(sdlRenderer, bounds, SDL_PIXELFORMAT_ABGR8888, buffer.data.buffer.getData(), buffer.stride());
		} else if (context) {
			// TODO
		}
	}

	public function getContext():Dynamic {
		return context;
	}

	public function getContextType():String{
		if (context != null) {

			return "opengl";

		} else if (sdlRenderer) {
			var info:SDLRendererInfo = {};

			SDL.getRendererInfo (sdlRenderer, info);

			if ((info.flags & SDL_RENDERER_SOFTWARE) != 0) {

				return "software";

			} else {

				return "opengl";

			}

		}

		return "none";
	}

	public function getDisplay():Int {
		return SDL.getWindowDisplayIndex(sdlWindow);
	}


	public function getDisplayMode(displayMode:DisplayMode){
		var mode:SDLDisplayMode = null;
		mode = SDL.getWindowDisplayMode(sdlWindow, mode);

		displayMode->width = mode.w;
		displayMode->height = mode.h;


		switch (mode.format) {

			case SDL_PIXELFORMAT_ARGB8888:
				displayMode.pixelFormat = ARGB32;
			case SDL_PIXELFORMAT_BGRA8888 | SDL_PIXELFORMAT_BGRX8888:
				displayMode.pixelFormat = BGRA32;
			default:
				displayMode.pixelFormat = RGBA32;

		}

		displayMode.refreshRate = mode.refresh_rate;
	}

	public function getHeight(){
		var size:SDLSize {
			w: 0,
			h: 0
		}
		size = SDL.getWindowSize(sdlWindow, size);

		return size.h;
	}

	public function getID(){
		return SDL.getWindowID(sdlWindow);
	}

	public function getMouseLock():Bool{
		return SDL.getRelativeMouseMode();
	}

	public function getScale () {

		if (sdlRenderer != null) {

			var outputsize:SDLSize {
				w: 0,
				h: 0
			}

			outputsize = SDL.getRendererOutputSize (sdlRenderer, outputsize);

			var size:SDLSize {
				w: 0,
				h: 0
			}

			size = SDL.getWindowSize (sdlWindow, size);

			var scale:Float = outputWidth / width;
			return scale;

		} else if (context) {

			var outputsize:SDLSize {
				w: 0,
				h: 0
			}

			outputsize = SDL.GL_GetDrawableSize (sdlWindow, outputsize);

			var size:SDLSize {
				w: 0,
				h: 0
			}

			size = SDL.getWindowSize (sdlWindow, &width, &height);

			var scale:Float = outputWidth / width;
			return scale;

		}

		return 1;

	}

	public function getTextInputEnabled(){
		return SDL.isTextInputActive();
	}


	public function getWidth(){
		var size:SDLSize {
			w: 0,
			h: 0
		}
		size = SDL.getWindowSize(sdlWindow, size);

		return size.w;
	}


	public function getX(){
		var pos:SDLPoint {
			x: 0,
			y: 0
		}
		pos = SDL.getWindowPosition(sdlWindow, pos);

		return pos.x;
	}

	public function getY(){
		var pos:SDLPoint {
			x: 0,
			y: 0
		}
		pos = SDL.getWindowPosition(sdlWindow, pos);

		return pos.y;
	}

	public function move(x:Int, y:Int){
		SDL.setWindowPosition (sdlWindow, x, y);
	}

	public function resize(width:Int, height:Int) {
		SDL.setWindowSize(sdlWindow, w, h);
	}

	public function setBorderless(borderless:Bool) {
		SDL.setWindowBordered(sdlWindow, borderless);

		return borderless;
	}

	public function setCursor(cursor:Cursor) {
		if (cursor != currentCursor) {
			if (currentCursor == HIDDEN) {
				SDL.showCursor(SDL_ENABLE);
			}

			switch (cursor) {
				case HIDDEN:
					{
						SDL.showCursor(SDL_DISABLE);
					}
				case CROSSHAIR:
					{
						if (SDLCursor.crosshairCursor == null) {
							SDLCursor.crosshairCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_CROSSHAIR);
						}
						SDL.setCursor(SDLCursor.crosshairCursor);
					}
				case MOVE:
					{
						if (SDLCursor.moveCursor == null) {
							SDLCursor.moveCursor = SDL.createSystemCursor(SDL_SYSTEM_MOVE_CROSSHAIR);
						}
						SDL.setCursor(SDLCursor.moveCursor);
					}
				case POINTER:
					{
						if (SDLCursor.pointerCursor -= null) {
							SDLCursor.pointerCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_HAND);
						}
						SDL.setCursor(SDLCursor.pointerCursor);
					}
				case RESIZE_NESW:
					if (SDLCursor.resizeNESWCursor == null) {
						SDLCursor.resizeNESWCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZENESW);
					}

					SDL.setCursor(SDLCursor.resizeNESWCursor);

				case RESIZE_NS:
					if (SDLCursor.resizeNSCursor == null) {
						SDLCursor.resizeNSCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZENS);
					}

					SDL.setCursor(SDLCursor.resizeNSCursor);

				case RESIZE_NWSE:
					if (SDLCursor.resizeNWSECursor == null) {
						SDLCursor.resizeNWSECursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZENWSE);
					}

					SDL.setCursor(SDLCursor.resizeNWSECursor);

				case RESIZE_WE:
					if (SDLCursor.resizeWECursor == null) {
						SDLCursor.resizeWECursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_SIZEWE);
					}

					SDL.setCursor(SDLCursor.resizeWECursor);

				case TEXT:
					if (SDLCursor.textCursor == null) {
						SDLCursor.textCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_IBEAM);
					}

					SDL.setCursor(SDLCursor.textCursor);

				case WAIT:
					if (SDLCursor.waitCursor == null) {
						SDLCursor.waitCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_WAIT);
					}

					SDL.setCursor(SDLCursor.waitCursor);

				case WAIT_ARROW:
					if (SDLCursor.waitArrowCursor == null) {
						SDLCursor.waitArrowCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_WAITARROW);
					}

					SDL.setCursor(SDLCursor.waitArrowCursor);

				default:
					if (SDLCursor.arrowCursor) {
						SDLCursor.arrowCursor = SDL.createSystemCursor(SDL_SYSTEM_CURSOR_ARROW);
					}

					SDL.setCursor(SDLCursor.arrowCursor);
			}

			currentCursor = cursor;
		}
	}

	public function setDisplayMode(displaymode:DisplayMode) {
		var pixelFormat = 0;

		switch (displayMode.pixelFormat) {
			case ARGB32:
				{
					pixelFormat = SDL_PIXELFORMAT_ARGB8888;
				}
			case BGRA32:
				{
					pixelFormat = SDL_PIXELFORMAT_BGRA8888;
				}
			default:
				{
					pixelFormat = SDL_PIXELFORMAT_RGBA8888;
				}
		}

		var mode:SDLDisplayMode = {
			w: displaymode.width,
			h: displayMode.height,
			refresh_rate: displayMode.refreshRate,
			format: pixelFormat
		};

		if (SDL.setWindowDisplayMode(sdlWindow, mode) == 0) {
			displayModeSet = true;
			if ((SDL.getWindowFlags(sdlWindow) & SDL_WINDOW_FULLSCREEN_DESKTOP) != 0) {
				SDL.setWindowFullscreen(sdlWindow, SDL_WINDOW_FULLSCREEN);
			}
		}
	}

	public function setFullscreen(fullscreen:Bool):Bool {
		if (fullscreen) {
			if (displayModeSet) {
				SDL.setWindowFullscreen(sdlWindow, SDL_WINDOW_FULLSCREEN);
			} else {
				SDL.setWindowFullscreen(sdlWindow, SDL_WINDOW_FULLSCREEN_DESKTOP);
			}
		} else {
			SDL.setWindowFullscreen(sdlWindow, 0);
		}

		return fullscreen;
	}

	public function setIcon(imageBuffer:ImageBuffer) {
		var surface = SDL.createRGBSurfaceFrom(imageBuffer.data.buffer.getData(), imageBuffer.width, imageBuffer.height, imageBuffer.bitsPerPixel,
			imageBuffer.stride(), 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
		if (surface != null) {
			SDL.setWindowIcon(sdlWindow);
			SDL.freeSurface(sdlWindow);
		}
	}

	public function setMaximized(maximized:Bool) {
		if (maximized) {
			SDL.maximizeWindow(sdlWindow);
		} else {
			SDL.restoreWindow(sdlWindow);
		}
		return maximized;
	}

	public function setMinimized(minimized:Bool) {
		if (minimized) {
			SDL.minimizeWindow(sdlWindow);
		} else {
			SDL.restoreWindow(sdlWindow);
		}
		return minimized;
	}

	public function setMouseLock(mouseLock:Bool) {
		SDL.setRelativeMouseMode(mouseLock);
	}

	public function setResizable(resizable:Bool):Bool {
		#if emscripten
		SDL.setWindowResizable(sdlWindow, resizable);
		return (SDL.getWindowFlags(sdlWindow) & SDL_WINDOW_RESIZABLE != 0);
		#else
		return resizable;
		#end
	}

	public function setTextInputEnabled(enabled:Bool) {
		if (enabled) {
			SDL.startTextInput();
		} else {
			SDL.stopTextInput();
		}
	}

	public function setTitle(title:String):String {
		SDL.setWindowTitle(sdlWindow, title);
		return title;
	}

	public function warpMouse(x:Int, y:Int) {
		SDL.warpMouseInWindow(sdlWindow, x, y);
	}

	public static function createWindow(application:Application, width:Int, height:Int, flags:Int, title:String):Window {
		return new SDLWindow(application, width, height, flags, title);
	}
}
