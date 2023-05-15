#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import pkg/chroma
# ndk dependencies
import nstd/types  as base
import nmath/types as m
from   nglfw       as glfw import nil
from   wgpu        import nil

#_______________________________________
# ngpu: Errors
#__________________
type DrawError * = object of IOError

#_______________________________________
# ngpu: Window
#__________________
type Window * = ref object
  ct     *:glfw.Window
  size   *:UVec2
  title  *:str

#_______________________________________
# ngpu: Elements
#__________________
type Instance * = ref object
  ct       *:wgpu.Instance
  cfg      *:wgpu.InstanceDescriptor
  label    *:str
#__________________
type Adapter * = ref object
  surface  *:wgpu.Surface
  ct       *:wgpu.Adapter
  cfg      *:wgpu.RequestAdapterOptions
  label    *:str
#__________________
type CommandBuffer * = ref object
  ct       *:wgpu.CommandBuffer
  cfg      *:wgpu.CommandBufferDescriptor
  label    *:str
#__________________
type CommandEncoder * = ref object
  ct       *:wgpu.CommandEncoder
  cfg      *:wgpu.CommandEncoderDescriptor
  label    *:str
#__________________
type Queue * = ref object
  ct       *:wgpu.Queue
  buffer   *:CommandBuffer
  encoder  *:CommandEncoder
#__________________
type Device * = ref object
  limits   *:wgpu.RequiredLimits
  features *:seq[wgpu.Feature]
  ct       *:wgpu.Device
  cfg      *:wgpu.DeviceDescriptor
  label    *:str
  queue    *:Queue   ## Device Queue. Contains the Command Buffer and Encoder
#__________________
type Swapchain * = ref object
  view     *:wgpu.TextureView
  ct       *:wgpu.Swapchain
  cfg      *:wgpu.SwapChainDescriptor
  label    *:str

#_______________________________________
# ngpu: Core
#__________________
type Renderer * = ref object of RootObj
  label      *:str
  win        *:Window
  bg         *:Color
  instance   *:Instance
  adapter    *:Adapter
  device     *:Device
  swapChain  *:Swapchain
  # cam        *:Camera
  # tech       *:RenderTechs


#_______________________________________
# ngpu: Tech
#__________________
type Tech *{.pure.}= enum Clear, Simple

# TODO:
type RenderTech  * = ref object
type RenderPhase * = ref object
type RenderPass  * = ref object


#_______________________________________
# ngpu: wgpu-to-ngpu auto Converters
#__________________
converter toBool *(list :seq[wgpu.Feature]) :bool=  list.len > 0
  ## Automatically converts a list of wgpu.Features to bool when empty.
converter toLimits *(lim :wgpu.Limits) :wgpu.RequiredLimits=  wgpu.RequiredLimits(nextInChain: nil, limits: lim)
  ## Automatically converts wgpu.RequiredLimits into wgpu.Limits

