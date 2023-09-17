#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
# Tests that ngpu loaded correctly.                 |
# Creates a wgpu.Instance and prints its address.   |
# Creates a window that remains open until closed.  |
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
  echo "Hello n*gpu"
  e.sys = nsys.init(cfg.res, title = cfg.Prefix&" | Hello") # Init the window+input
  ngpu.tests.basic()                                        # Run the test
  while not e.sys.close(): e.sys.update()                   # Keep the window open
  e.sys.term()                                              # Terminate the window
#__________________
when isMainModule: run()
