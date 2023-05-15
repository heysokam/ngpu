#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# ndk dependencies
import nstd/types as base
import nstd/C/address
from   nglfw      as glfw import nil
import nmath
# ngpu dependencies
import ./types
import ./tools/logger


#________________________________________________
# Helpers
#__________________
func ratio *(w :Window) :f32=  w.size.x.float32/w.size.y.float32
  ## Returns the window size ratio as a float32
func getSize *(w :var Window) :UVec2=
  ## Returns a Vector2 containing the most current window size.
  ## Also updates the stored value at `window.size`
  glfw.getWindowSize(w.ct, result.x.iaddr, result.y.iaddr)
  w.size = result


#________________________________________________
# Default Callbacks
#__________________
proc error *(code :int32; desc :cstring) :void {.cdecl, discardable.} =
  ## GLFW error callback
  err &"Error:{code} {desc}"
  err $desc


#________________________________________________
# General
#__________________
proc new *(_:typedesc[Window]; 
    res         : UVec2;
    title       : str                     = "ngpu";
    resizable   : bool                    = true;
    resize      : glfw.FrameBufferSizeFun = nil;
    key         : glfw.KeyFun             = nil;
    mousePos    : glfw.CursorPosFun       = nil;
    mouseBtn    : glfw.MouseButtonFun     = nil;
    mouseScroll : glfw.ScrollFun          = nil;
    error       : glfw.ErrorFun           = error;
  ) :Window=
  ## Initializes and returns a new window with GLFW.
  discard glfw.setErrorCallback(error)
  doAssert glfw.init(), "Failed to Initialize GLFW"
  glfw.windowHint(glfw.CLIENT_API, glfw.NO_API)
  glfw.windowHint(glfw.Resizable, if resizable: glfw.True else: glfw.False)
  new result
  result.size  = res
  result.title = title
  result.ct    = glfw.createWindow(res.x.int32, res.y.int32, title.cstring, nil, nil)
  doAssert result.ct != nil, "Failed to create GLFW window"
  discard glfw.setKeyCallback(result.ct, key)
  discard glfw.setCursorPosCallback(result.ct, mousePos)
  discard glfw.setMouseButtonCallback(result.ct, mouseBtn)
  discard glfw.setScrollCallback(result.ct, mouseScroll)
  discard glfw.setFramebufferSizeCallback(result.ct, resize)  # Set viewport size/resize callback

#__________________
template init *(win :var Window;
    res         : UVec2;
    title       : str                     = "ngpu";
    resizable   : bool                    = true;
    resize      : glfw.FrameBufferSizeFun = nil;
    key         : glfw.KeyFun             = nil;
    mousePos    : glfw.CursorPosFun       = nil;
    mouseBtn    : glfw.MouseButtonFun     = nil;
    mouseScroll : glfw.ScrollFun          = nil;
    error       : glfw.ErrorFun           = error;
  ) :Window=
  ## Initializes and returns a new window with GLFW.
  ## Alias for win = Window.new( ... )
  win = Window.new(res, title, resizable, resize, key, mousePos, mouseBtn, mouseScroll, error)
#__________________
proc close  *(win :Window) :bool=  glfw.windowShouldClose(win.ct)
  ## Returns true when the GLFW window has been marked to be closed.
proc term   *(win :Window) :void=  glfw.destroyWindow(win.ct); glfw.terminate()
  ## Terminates the GLFW window.
proc update *(win :Window) :void=  glfw.pollEvents()
  ## Updates the window. Needs to be called each frame.

