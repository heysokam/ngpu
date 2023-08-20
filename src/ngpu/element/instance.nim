#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# n*dk dependencies
import nstd/types as base
# n*gpu dependencies
import ../types as ngpu


#___________________
proc new *(_:typedesc[ngpu.Instance];
    label :str= "ngpu | Instance"
  ) :ngpu.Instance=
  new result
  result.label = label
  result.cfg   = wgpu.InstanceDescriptor(nextInChain: nil)  # TODO: wgpu extension for Backend Selection
  result.ct    = wgpu.create(result.cfg.addr)
  doAssert result.ct != nil, "Could not initialize the wgpu instance"

