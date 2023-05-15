#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Most minimal draw possible.         |
# Just clears the screen to a color.  |
#_____________________________________|
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
  echo "ngpu | Hello Clear"
  # Init a new Renderer
  e.render = Renderer.new(
    title = "ngpu | Hello Clear",
    label = "ngpu",
    res   = cfg.res,
    key   = key,
    ) # << state.render.init()
  # Update loop
  while not e.render.close():
    e.render.draw(Tech.Clear)
  # Terminate
  e.render.term()

#________________________________________________
when isMainModule: run()

