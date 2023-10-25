#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
# Package
packageName   = "ngpu"
version       = "0.1.7"
author        = "sOkam"
description   = "n*gpu | Graphics Library | WebGPU"
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
import std/strformat
task push, "Helper:  Pushes the git repository, and orders to create a new git tag for the package, using the latest version.":
  ## Does nothing when local and remote versions are the same.
  requires "https://github.com/beef331/graffiti.git"
  exec "git push"  # Requires local auth
  exec &"graffiti ./{packageName}.nimble"
#_____________________________
template build (name :untyped; descr :static string)=
  ## Generates a task to build+run the given example
  taskRequires astToStr(name), "https://github.com/heysokam/confy#head"
  task name, descr: exec &"nim -d:cnimble confy.nims {astToStr(name)}"


#_______________________________________
# Examples
build wip,       "Example WIP: Builds the latest/current wip tutorial app."
build hello,     "Example 00:  hello window+instance"
build clear,     "Example 01:  clear window"
build triangle,  "Example 02:  hello triangle"
build buffer,    "Example 03:  hello buffer"
build triangle4, "Example 07:  indexed multi-buffered triangle."
build struct,    "Example 09:  uniform struct."
# build dynamic,   "Example 10:  uniform struct."
build texture,   "Example 11:  simple pixel texture."
build texture2,  "Example 12:  sampled pixel texture."
build depth,     "Example 13:  simple depth buffer attachment."
build camera,    "Example 14:  simple 3D camera controller."
build instance, " Example 16:  cube instanced 100 times."
build multimesh, "Example 17:  multi-mesh. cubes + pyramid."
