#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
import std/os
import std/strformat
import std/strutils

##[  DEV NOTE:
# Include this file into your `PROJECT/name.nimble` file:
include ngpu/nimble
# This will give access to the default config helpers of ngpu
]##

#_____________________________
# Folders
#___________________
srcDir           = "src"
binDir           = "bin"
var testsDir     = "tests"
var examplesDir  = "examples"
var docDir       = "doc"

#________________________________________
# Helpers
#___________________
const vlevel = when defined(debug): 2 else: 1
let nimcr  = &"nimble c -r --verbose --verbosity:{vlevel} --outdir:{binDir}"
  ## Compile and run, outputting to binDir
proc runFile (file, dir :string) :void=  exec &"{nimcr} {dir/file}"
  ## Runs file from the given dir, using the nimcr command
proc runTest (file :string) :void=  file.runFile(testsDir)
  ## Runs the given test file. Assumes the file is stored in the default testsDir folder
proc runExample (file :string) :void=  file.runFile(examplesDir)
  ## Runs the given test file. Assumes the file is stored in the default testsDir folder

#________________________________________
# Extra tasks
#___________________

