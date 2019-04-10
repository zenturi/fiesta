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

// import sdl.SDL.WindowFlags;
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

	private var context:GLContext;
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
			sdlWindowFlags |= SDL_WindowFlags.SDL_WINDOW_FULLSCREEN_DESKTOP;
		if ((flags & WINDOW_FLAG_RESIZABLE) != -1){
            sdlWindowFlags |= SDL_WindowFlags.SDL_WINDOW_RESIZABLE;
        }
		if ((flags & WINDOW_FLAG_BORDERLESS) != 0)
			sdlWindowFlags |= SDL_WindowFlags.SDL_WINDOW_BORDERLESS;
		if ((flags & WINDOW_FLAG_HIDDEN) != 0)
			sdlWindowFlags |= SDL_WindowFlags.SDL_WINDOW_HIDDEN;
		if ((flags & WINDOW_FLAG_MINIMIZED) != 0)
			sdlWindowFlags |= SDL_WindowFlags.SDL_WINDOW_MINIMIZED;
		if ((flags & WINDOW_FLAG_MAXIMIZED) != 0)
			sdlWindowFlags |= SDL_WindowFlags.SDL_WINDOW_MAXIMIZED;

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

        sdlWindow = SDL.createWindow (title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);

        #if (ios || tvos)
        if (sdlWindow != null && SDL.GL_CreateContext (sdlWindow) != null) {

			SDL.destroyWindow (sdlWindow);
			SDL.GL_SetAttribute (SDL_GL_CONTEXT_MAJOR_VERSION, 2);

			sdlWindow = SDL.createWindow (title, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, sdlWindowFlags);

		}
        #end

        if (sdlWindow == null) {

			throw 'Could not create SDL window: ${SDL.getError ()}';

		}

        #if (windows && !winrt)
        untyped __cpp__('
        // #if defined (HX_WINDOWS) && !defined (HX_WINRT)

		HINSTANCE handle = ::GetModuleHandle (nullptr);
		HICON icon = ::LoadIcon (handle, MAKEINTRESOURCE (1));

		if (icon != nullptr) {

			SDL_SysWMinfo wminfo;
			SDL_VERSION (&wminfo.version);

			if (SDL_GetWindowWMInfo (sdlWindow, &wminfo) == 1) {

				HWND hwnd = wminfo.info.win.window;

				#ifdef _WIN64
				::SetClassLongPtr (hwnd, GCLP_HICON, reinterpret_cast<LONG_PTR>(icon));
				#else
				::SetClassLong (hwnd, GCL_HICON, reinterpret_cast<LONG>(icon));
				#endif

			}

		}

		// #endif
        int nothing');
        #end

        var sdlRendererFlags = 0;

        if ((flags & WINDOW_FLAG_HARDWARE) != 0) {
            sdlRendererFlags |= SDL_RENDERER_ACCELERATED;

            context = SDL.GL_CreateContext (sdlWindow);

            

            if (context  != null && SDL.GL_MakeCurrent (sdlWindow, context) == 0) {
                if ((flags & WINDOW_FLAG_VSYNC) != 0) {
                    SDL.GL_SetSwapInterval (true);
                } else {
                    SDL.GL_SetSwapInterval (false);
                }
                #if (linc_opengl_EGL || linc_opengl_GLES || linc_opengl_GLES1 || linc_opengl_GLES2 || linc_opengl_GLES3)
                var version = 0;
                GL.glGetIntegerv(GL.GL_MAJOR_VERSION, [version]);
               if(version == 0){
                   var versionScan = 0;
                   untyped __cpp__('sscanf ((const char*)glGetString (GL_VERSION), "%f", &versionScan)');

                   version = versionScan;
               }

               if(version < 2 && Pointer.fromRaw(GL.glGetString(GL.GL_VERSION)).get_ref().toString() == "OpenGL ES"){
                    SDL.GL_DeleteContext (context);
					context = null;
               }

                
               #elseif  (ios || tvos)
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

			sdlRenderer = SDL.createRenderer (sdlWindow, -1, sdlRendererFlags);

		}

		if (context  != null|| sdlRenderer != null) {

			cast(currentApplication, SDLApplication).registerWindow (this);

		} else {

			throw 'Could not create SDL renderer: ${SDL.getError ()}';

		}

	}
}
