#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
include src/ngpu/nimble

#___________________
# Package
packageName   = "ngpu"
version       = "0.0.0"
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
# ngpu specific nimble config
skipdirs = @[binDir, examplesDir, testsDir, docDir]  # Tell nimble what folders to skip in the package

#___________________
task tut, "     Builds the latest/current wip tutorial app.":  runExample "tut"
#___________________
task hello, "   Example 00:  hello window+instance":  runExample "e00_hellongpu"
task clear, "   Example 01:  clear window":           runExample "e01_helloclear"
task triangle, "Example 02:  hello triangle":         runExample "e02_hellotriangle"
task buffer, "  Example 03:  hello buffer":           runExample "e03_hellobuffer"

