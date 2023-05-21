#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types as base
# ngpu dependencies
import ../types as ngpu


#_______________________________________
# Command Buffer
#___________________
proc new *(_:typedesc[ngpu.CommandBuffer];
    encoder : ngpu.CommandEncoder;
    label   : str = "ngpu | CommandBuffer";
  ) :ngpu.CommandBuffer=
  new result
  result.label = label
  result.cfg   = CommandBufferDescriptor(
    nextInChain : nil,
    label       : label,
    ) # << CommandBufferDescriptor
  result.ct = encoder.ct.finish(result.cfg.addr)


#________________________________________________
# Command Encoder
#___________________
proc new *(_:typedesc[ngpu.CommandEncoder];
    device : ngpu.Device;
    label  : str = "ngpu | Command Encoder";
  ) :ngpu.CommandEncoder=
  new result
  result.label = label
  result.cfg   = CommandEncoderDescriptor(
    nextInChain  : nil,
    label        : label,
    ) # << CommandEncoderDescriptor()
  result.ct = device.ct.create(result.cfg.addr)
#___________________
proc update *(encoder :var ngpu.CommandEncoder; device :ngpu.Device) :void=
  ## Updates the given encoder with a new one.
  ## Meant to be called each frame by spec.
  encoder = ngpu.CommandEncoder.new(device, encoder.label)


#_______________________________________
# Queue
#___________________
proc get *(device :wgpu.Device; _:typedesc[wgpu.Queue]) :wgpu.Queue=  wgpu.getQueue(device)
  ## Gets the Queue handle of the given physical device

proc new *(_:typedesc[ngpu.Queue];
    device : ngpu.Device;
  ) :ngpu.Queue=
  new result
  result.ct = device.ct.get(wgpu.Queue)
  # Create a throwaway Buffer and Encoder (will be replaced each frame)
  result.buffer  = new ngpu.CommandBuffer
  result.encoder = new ngpu.CommandEncoder

