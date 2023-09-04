#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
import std/[ os,strformat ]

#___________________
# Package
packageName   = "ngpu"
version       = "0.1.2"
author        = "sOkam"
description   = "n* Graphics Library | WebGPU"
license       = "MIT"

#___________________
# Build requirements
requires "nim >= 2.0.0"
requires "chroma"
requires "pixie"
# n*dk requirements
requires "https://github.com/heysokam/nmath"
requires "https://github.com/heysokam/nsys" ## For window creation. GLFW interaction, without dynamic libraries required
requires "https://github.com/heysokam/wgpu"

#___________________
# Folders
srcDir           = "src"
binDir           = "bin"
var testsDir     = "tests"
var examplesDir  = "examples"
var docDir       = "doc"


#________________________________________
# Helpers
#___________________
const vlevel = when defined(debug): 2 else: 1
let nimcr  = &"nim c -r --verbosity:{vlevel} --outdir:{binDir}"
  ## Compile and run, outputting to binDir
proc runFile (file, dir :string) :void=  exec &"{nimcr} {dir/file}"
  ## Runs file from the given dir, using the nimcr command
proc runTest (file :string) :void=  file.runFile(testsDir)
  ## Runs the given test file. Assumes the file is stored in the default testsDir folder
proc runExample (file :string) :void=  file.runFile(examplesDir)
  ## Runs the given test file. Assumes the file is stored in the default testsDir folder
template example (name :untyped; descr,file :static string)=
  ## Generates a task to build+run the given example
  let sname = astToStr(name)  # string name
  taskRequires sname, "https://github.com/heysokam/nstd"
  task name, descr:
    runExample file

#___________________
#___________________
example wip,       "Example WIP: Builds the latest/current wip tutorial app.", "wip"
example hello,     "Example 00:  hello window+instance",                       "e00_hellongpu"
example clear,     "Example 01:  clear window",                                "e01_helloclear"
example triangle,  "Example 02:  hello triangle",                              "e02_hellotriangle"
example buffer,    "Example 03:  hello buffer",                                "e03_hellobuffer"
example triangle4, "Example 07:  indexed multi-buffered triangle.",            "e07_trianglebuffered3"
example struct,    "Example 09:  uniform struct.",                             "e09_uniformstruct"
# example dynamic,   "Example 10:  uniform struct.",                             "e10_dynamicuniform"
example texture,   "Example 11:  simple pixel texture.",                       "e11_hellotexture"
example texture2,  "Example 12:  sampled pixel texture.",                      "e12_sampledtexture"
example depth,     "Example 13:  simple depth buffer attachment.",             "e13_hellodepth"
example camera,    "Example 14:  simple 3D camera controller.",                "e14_hellocamera"
example instance, " Example 16:  cube instanced 100 times.",                   "e16_cubeinstanced"
example multimesh, "Example 17:  multi-mesh. cubes + pyramid.",                "e17_multimesh"

#___________________
# Helper Tasks
task push, "Helper:  Pushes the git repository, and orders to create a new git tag for the package, using the latest version.":
  ## Does nothing when local and remote versions are the same.
  requires "https://github.com/beef331/graffiti.git"
  exec "git push"  # Requires local auth
  exec &"graffiti ./{packageName}.nimble"

