#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
# Hello Triangle from wgpu-native/examples          |
# No buffers. Vertices are harcoded in the shader.  |
#___________________________________________________|
# n*dk dependencies
import nsys
# n*gpu dependencies
import ngpu
# Examples dependencies
import ./cfg
import ./state as e

#________________________________________________
# Entry Point
#__________________
proc run=
  echo cfg.Prefix&" | Hello Triangle"
  # Init the window+input and Renderer
  e.sys    = nsys.init(cfg.res, title = cfg.Prefix&" | Hello Triangle") # << state.sys.init()
  e.render = ngpu.new(Renderer, system = e.sys, label = cfg.Prefix) # << state.render.init()
  # Init the RenderTech
  var tech = e.render.init(Tech.Triangle)
  # Update loop
  while not e.sys.close():
    e.sys.update()
    e.render.draw(tech)
  # Terminate
  e.render.term()
  e.sys.term()

#________________________________________________
when isMainModule: run()

