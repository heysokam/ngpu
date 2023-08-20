#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Tests that ngpu loaded correctly.                 |
# Creates a wgpu.Instance and prints its address.   |
# Creates a window that remains open until closed.  |
#___________________________________________________|
# n*gpu dependencies
import ngpu
# Examples dependencies
import ./cfg
import ./state as e
import ./extras

#__________________
# Inputs
from nglfw as glfw import nil
proc key (win :glfw.Window; key, code, action, mods :cint) :void {.cdecl.}=
  ## GLFW Keyboard Input Callback
  if (key == glfw.KeyEscape and action == glfw.Press):
    glfw.setWindowShouldClose(win, true)

#________________________________________________
# Entry Point
#__________________
proc run=
  echo "Hello ngpu"
  e.sys = nsys.init(
    res   = cfg.res,
    title = "ngpu | Hello ngpu",
    # key   = key,
    ) # << state.sys.init()
  ngpu.tests.basic()
  while not e.sys.close():
    e.sys.update()
  e.sys.term()
#__________________
when isMainModule: run()

