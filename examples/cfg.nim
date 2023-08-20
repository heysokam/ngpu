#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# n*dk dependencies
import nstd/time
import nmath

#____________________
# General Config
const maxDelta *:Duration=  initDuration(milliseconds = 1000 div 4)

#____________________
# Rendering
const res       * = uvec2(960, 540)  ## Default window resolution the engine will launch with
const resizable * = false            ## Whether the engine's window is resizable by default or not
const vsync     * = false            ## Whether to have vsync active by default or not
# const cam       * = newCamera(
#   origin = vec3(40,120,40),
#   target = vec3(0,0,0),
#   up     = vec3(0,1,0),
#   fov    = 45.0,
#   near   = 0.1,
#   far    = 10000.0)

