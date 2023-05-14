#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Tests that ngpu loaded correctly.                 |
# Creates a wgpu.Instance and prints its address.   |
# Creates a window that remains open until closed.  |
#___________________________________________________|
# ngpu dependencies
import ngpu
# Examples dependencies
import ./cfg
import ./state as e

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
  e.window = Window.new(
    title = "ngpu | Hello ngpu",
    res   = cfg.res,
    key   = key,
    ) # << state.window.init()
  ngpu.tests.basic()
  while not e.window.close():
    e.window.update()
  e.window.term()
#__________________
when isMainModule: run()

