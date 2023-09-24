#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
when not defined(nimble):
  import ../../confy/src/confy
else:
  import confy

import std/os except `/`
#[
proc clean (trg :BuildTrg) :void=
  os.removeDir(cfg.cacheDir)
  os.removeFile(cfg.binDir/trg.trg)
]#

const memdebug :bool= on
const release  :bool= off

#________________________________________
# Build tasks
#___________________
template example *(name :untyped; descr,file :static string)=
  ## Custom examples alias (per project)
  const deps :seq[string]= @[
  ""
  ] # Examples: Build Requirements
  const args :seq[string]= @[
    "--path:\"../src/\"",
    # "--d:release",
    when memdebug:
      "--listCmd",
      "--passC:\"-ggdb\"",
      "--passC:\"-O0\"",
      # "--debugger:native",
      # "--passc:\"-fsanitize=undefined\"",
      "--passC:\"-fsanitize=address\"",
      "--passL:\"-fsanitize=address\"",
      "--passL:\"-lasan\"",
      "--passL:\"-shared-libasan\"",
      "--d:useMalloc",
    ]
  os.removeFile(cfg.binDir/astToStr(name))
  example name, descr, file, deps, args, true, true
  # os.removeFile(cfg.binDir/astToStr(name))

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

