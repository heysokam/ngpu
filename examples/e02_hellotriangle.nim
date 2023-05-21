#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Hello Triangle from wgpu-native/examples          |
# No buffers. Vertices are harcoded in the shader.  |
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
  echo "ngpu | Hello Triangle"
  # Init a new Renderer
  e.render = Renderer.new(
    title = "ngpu | Hello Triangle",
    label = "ngpu",
    res   = cfg.res,
    key   = key,
    ) # << state.render.init()
  # Update loop
  var tech = e.render.init(Tech.Triangle)
  while not e.render.close():
    e.render.draw(tech)
  # Terminate
  e.render.term()

#________________________________________________
when isMainModule: run()

