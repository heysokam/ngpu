#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# ndk dependencies
import nstd/types  as base
# ngpu dependencies
import ../../types as ngpu
import ../../element/bindings
import ../../element/data

# Exports required by other modules that call this element
export data.genCode
export data.getCode
export data.initCode
export data.initBinding

#_______________________________________
# RenderData: Construct
#___________________
proc new *[T](render :var Renderer;
    _       : typedesc[RenderData[T]];
    data    : T;
    varName : str;
    upload  : bool = false;
    label   : str  = "ngpu | RenderData";
  ) :RenderData[T]=
  # TODO: RenderData register for Multi-pass Techniques
  RenderData[T].new(
    data    = data,
    varName = varName,
    device  = render.device,
    upload  = upload,
    label   = label & &" {$T}",
    ) # << RenderData.new( ... )

