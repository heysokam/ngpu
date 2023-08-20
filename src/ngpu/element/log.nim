#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# n*gpu dependencies
from   ../callbacks as cb import nil


#___________________
proc set *(logLevel :wgpu.LogLevel; logCB :wgpu.LogCallback= cb.log) :void=
  ## Initialize wgpu logging with the given level and callback.
  wgpu.set logCB, nil
  wgpu.set logLevel
#___________________
proc initLog *() :void=  set(wgpu.LogLevel.warn, cb.log)
  ## Initialize wgpu logging with ngpu defaults.
  ## Alias for ergonomics.

