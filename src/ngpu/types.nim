#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# ndk dependencies
import nstd/types  as base
import nmath/types as m
from   nglfw       as glfw import nil


type Window * = ref object
  ct     *:glfw.Window
  size   *:UVec2
  title  *:str

