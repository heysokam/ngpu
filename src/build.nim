#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
# std dependencies
import std/os except `/`
import std/sets
import std/strformat
# confy dependencies
when not defined(nimble):
  import ../../confy/src/confy
else:
  import confy


#________________________________________
# Configuration
#___________________
# Custom
const debug       :bool= on
const memdebug    :bool= on and debug
const release     :bool= not debug
const alwaysClean :bool= on
# Confy
cfg.verbose = debug
cfg.flags   = allC

#________________________________________
# Helpers
#___________________
proc exec (file :string) :void=
  when memdebug : sh file
  elif debug    : sh &"nim-gdb -ex run " & file
  else          : sh file

#________________________________________
# Build tasks
#___________________
let keywordList = confy.getList()
#___________________
template example *(name :untyped; descr,file :static string)=
  ## Custom examples alias (per project)
  const deps :seq[string]= @[
  ""
  ] # Examples: Build Requirements
  var args :seq[string]= @[ "--path:\"../src/\"", ]
  when release  : args &= @[ "--d:release", ]
  elif debug    : args &= @[ "--d:debug", "--listCmd", "--passC:\"-O0 -ggdb\"", ]
  when memdebug : args &= @[
    "--passC:\"-fsanitize=undefined,address\"",
    "--passL:\"-fsanitize=undefined,address\"",
    "--passL:\"-lasan -shared-libasan\"",
    "-d:useMalloc",
    ]
  else: args &= @[ "--debugger:native", ]
  let sname = astToStr(name)
  let fname = cfg.binDir/sname
  if alwaysClean: os.removeFile(fname)
  example name, descr, file, deps, args, false, true
  if sname in keywordList and fname.fileExists(): exec fname
  if alwaysClean: os.removeFile(fname)

# Build the examples binaries
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

