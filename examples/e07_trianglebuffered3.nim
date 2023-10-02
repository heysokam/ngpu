#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Buffer-based Indexed Triangle                       |____________
# Includes examples of trianglebuffered 1, 2 and 3 from wgpu-nim.  |
#__________________________________________________________________|
# n*dk dependencies
import nstd
import nsys
# n*gpu dependencies
import ngpu
# Examples dependencies
import ./cfg
import ./state as e


#__________________
# Dependencies specific to this example
import ngpu/tech/shared/gen               # Triangle geometry
import ngpu/tech/simple/shader as simple  # Tech.Simple inits without code unless specified


#________________________________________________
# Entry Point
#__________________
proc run=
  echo "ngpu | Hello Buffered Triangle"
  #__________________
  # Init the window+input and Renderer
  e.sys    = nsys.init(cfg.res, title = cfg.Prefix&" | Hello Buffered Triangle") # << state.sys.init()
  e.render = ngpu.new(Renderer, system = e.sys, label = cfg.Prefix) # << state.render.init()
  #__________________
  # Init the Technique and Mesh
  var triangle = e.render.new(RenderMesh, gen.triangle())
  var tech     = e.render.init(Tech.Simple, simple.Code)
  e.render.upload(triangle)
  #__________________
  # Update loop
  while not e.sys.close():
    e.sys.update()
    e.render.draw(triangle, tech)
  #__________________
  # Terminate
  e.render.term()
  e.sys.term()


#________________________________________________
when isMainModule: run()

