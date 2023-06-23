#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
include src/ngpu/nimble  # TODO: Remove `src` before publishing

#___________________
# Package
packageName   = "ngpu"
version       = "0.0.4"
author        = "sOkam"
description   = "n* Graphics Library | WebGPU"
license       = "MIT"

#___________________
# Build requirements
requires "nim >= 1.6.12"
requires "chroma"
requires "pixie"
# n* DevKit
# requires "https://github.com/heysokam/nstd"
requires "https://github.com/heysokam/nmath"
requires "https://github.com/heysokam/nglfw"
# TODO: Take from github after package tag creation has been figured out (with beef's `graffiti` automation)
# requires "https://github.com/heysokam/wgpu"

#___________________
task tut, "     Builds the latest/current wip tutorial app.":  runExample "tut"
#___________________
task hello, "    Example 00:  hello window+instance"            : runExample "e00_hellongpu"
task clear, "    Example 01:  clear window"                     : runExample "e01_helloclear"
task triangle, " Example 02:  hello triangle"                   : runExample "e02_hellotriangle"
task buffer, "   Example 03:  hello buffer"                     : runExample "e03_hellobuffer"
task triangle4, "Example 07:  indexed multi-buffered triangle." : runExample "e07_trianglebuffered3"
task struct, "   Example 09:  uniform struct."                  : runExample "e09_uniformstruct"
# task dynamic, "  Example 10:  uniform struct."                  : runExample "e10_dynamicuniform"
task texture, "  Example 11:  simple pixel texture."            : runExample "e11_hellotexture"
task texture2, " Example 12:  sampled pixel texture."           : runExample "e12_sampledtexture"
task depth, "    Example 13:  simple depth buffer attachment."  : runExample "e13_hellodepth"
task camera, "   Example 14:  simple 3D camera controller."     : runExample "e14_hellocamera"
# task instance, " Example 16:  cube instanced 100 times."        : runExample "e16_cubeinstanced"
# task multimesh, "Example 17:  multi-mesh. cubes + pyramid."     : runExample "e17_multimesh"

