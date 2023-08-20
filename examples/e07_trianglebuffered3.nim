#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Buffer-based Indexed Triangle                       |____________
# Includes examples of trianglebuffered 1, 2 and 3 from wgpu-nim.  |
#__________________________________________________________________|
# n*dk dependencies
import nstd
# n*gpu dependencies
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


#__________________
# Dependencies specific to this example
import ngpu/tech/shared/gen


#________________________________________________
# Entry Point
#__________________
proc run=
  echo "ngpu | Hello Buffered Triangle"
  #__________________
  # Init a new Renderer
  e.render = Renderer.new(
    title = "ngpu | Hello Buffered Triangle",
    label = "ngpu",
    res   = cfg.res,
    key   = key,
    ) # << state.render.init()
  #__________________
  # Init the Technique and Mesh
  var tech     = e.render.init(Tech.Simple)
  var triangle = e.render.new(RenderMesh, gen.triangle())
  e.render.upload(triangle)
  #__________________
  # Update loop
  while not e.render.close():
    e.render.draw(triangle, tech)
  #__________________
  # Terminate
  e.render.term()


#________________________________________________
when isMainModule: run()

