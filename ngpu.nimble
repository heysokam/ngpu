#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
# Package
packageName   = "ngpu"
version       = "0.1.7"
author        = "sOkam"
description   = "n*gpu | Graphics Library"
license       = "MIT"
srcDir        = "src"
skipFiles     = @["build.nim", "nim.cfg"]
# Build requirements
requires "nim >= 2.0.0"
# n*dk requirements
requires "https://github.com/heysokam/nmath#head"
requires "https://github.com/heysokam/wgpu#head"
requires "https://github.com/heysokam/nsys#head" ## For window creation. GLFW interaction, without dynamic libraries required
requires "https://github.com/heysokam/nimp#head" ## For resources importing


#____________________________________________________
# Internal Management
#_____________________________
import std/[ strformat, strutils ]
task push, "Helper:  Pushes the git repository, and orders to create a new git tag for the package, using the latest version.":
  ## Does nothing when local and remote versions are the same.
  requires "https://github.com/beef331/graffiti.git"
  exec "git push"  # Requires local auth
  exec &"graffiti ./{packageName}.nimble"
#_____________________________
binDir = "bin"
template build (name :untyped; descr,file :static string)=
  ## Generates a task to build+run the given example
  task name, descr: exec &"nim c -r -o:$2 --outDir:$1 examples/$3.nim" % [binDir, astToStr(name), file]


#_______________________________________
# Examples
build wip,       "Example WIP: Builds the latest/current wip tutorial app.", "wip"
build hello,     "Example 00:  hello window+instance",                       "e00_hellongpu"
build clear,     "Example 01:  clear window",                                "e01_helloclear"
build triangle,  "Example 02:  hello triangle",                              "e02_hellotriangle"
build buffer,    "Example 03:  hello buffer",                                "e03_hellobuffer"
build triangle4, "Example 07:  indexed multi-buffered triangle.",            "e07_trianglebuffered3"
build struct,    "Example 09:  uniform struct.",                             "e08_uniformstruct"
# build dynamic,   "Example 10:  uniform struct."
build texture,   "Example 11:  simple pixel texture.",                       "e11_hellotexture"
build texture2,  "Example 12:  sampled pixel texture.",                      "e12_sampledtexture"
build depth,     "Example 13:  simple depth buffer attachment.",             "e13_hellodepth"
build camera,    "Example 14:  simple 3D camera controller.",                "e14_hellocamera"
build instance, " Example 16:  cube instanced 100 times.",                   "e16_cubeinstanced"
build multimesh, "Example 17:  multi-mesh. cubes + pyramid.",                "e17_multimesh"
