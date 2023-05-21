#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types  as base
# ngpu dependencies
import ../types    as ngpu


#___________________
proc new *(_:typedesc[Shader];
    device          :ngpu.Device;
    label,code,file :str;
  ) :Shader=
  ## Creates a new Shader with the given data
  new result
  result.label = label
  result.code  = code 
  result.file  = file
  result.cfg   = result.code.wgslToDescriptor(label = result.label)
  result.ct    = device.ct.create(result.cfg.addr)

