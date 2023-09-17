#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
# Most minimal draw possible.         |
# Just clears the screen to a color.  |
#_____________________________________|
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
  echo cfg.Prefix&" | Hello Clear"
  # Init the window+input and Renderer
  e.sys    = nsys.init(cfg.res, title = cfg.Prefix&" | Hello Clear") # << state.sys.init()
  e.render = ngpu.new(Renderer, system = e.sys, label = cfg.Prefix) # << state.render.init()
  # Update loop
  while not e.sys.close():
    e.sys.update()
    e.render.draw(Tech.Clear)
  # Terminate
  e.render.term()
  e.sys.term()

#________________________________________________
when isMainModule: run()

