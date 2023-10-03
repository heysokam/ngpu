#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# n*dk dependencies
import nsys
# n*gpu dependencies
import ngpu/types as ngpu
import ./types    as ex

#__________________
# Global
var sys    *:nsys.System
var render *:ngpu.Renderer
var cam    *:ex.Camera
var i      *:ex.Inputs

