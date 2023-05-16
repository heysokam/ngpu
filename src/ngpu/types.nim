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
# ngpu: Constants
#__________________
const NoFile * = "UndefinedFile.ext"

#_______________________________________
# ngpu: Errors
#__________________
type DrawError * = object of IOError
type InitError * = object of IOError

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
# Elements
const VertMain * = "vert"  ## Default name for the entry point of the vertex   shader
const FragMain * = "frag"  ## Default name for the entry point of the fragment shader
type  Shader   * = ref object
  ct     *:wgpu.ShaderModule
  cfg    *:wgpu.ShaderModuleDescriptor
  label  *:str
  code   *:str
  file   *:str
#__________________
type Pipeline * = ref object
  shader   *:Shader
  ct       *:wgpu.RenderPipeline
  cfg      *:wgpu.RenderPipelineDescriptor
  label    *:str
#__________________
type Texture * = ref object
  ct       *:wgpu.Texture
  view     *:wgpu.TextureView
  label    *:str

#__________________
# Core
type RenderTarget * = ref object
  texture  *:Texture
  ct       *:wgpu.RenderPassEncoder
  cfg      *:wgpu.RenderPassDescriptor
  label    *:str
#__________________
type RenderPass * = ref object
  pipeline *:Pipeline
  trg      *:RenderTarget
  label    *:str
#__________________
# TODO
type RenderPhase * = ref object
  pass     *:seq[RenderPass]
  label    *:str
#__________________
type Tech *{.pure.}= enum Unknown, Clear, Triangle, Simple
type RenderTech  * = ref object
  kind     *:Tech
  phase    *:seq[RenderPhase]
  label    *:str


#_______________________________________
# ngpu: wgpu-to-ngpu auto Converters
#__________________
converter toBool *(list :seq[wgpu.Feature]) :bool=  list.len > 0
  ## Automatically converts a list of wgpu.Features to bool when empty.
converter toLimits *(lim :wgpu.Limits) :wgpu.RequiredLimits=  wgpu.RequiredLimits(nextInChain: nil, limits: lim)
  ## Automatically converts wgpu.RequiredLimits into wgpu.Limits

