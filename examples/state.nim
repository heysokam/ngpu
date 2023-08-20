#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# n*dk dependencies
import nsys
# n*gpu dependencies
import ngpu/types
import ./extras

#__________________
# e00
var sys *:nsys.System

#__________________
# Global
var render *:Renderer
var cam    *:Camera

