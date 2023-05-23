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
# Exports
#__________________
export wgpu.BufferUsage
export chroma.Color

#_______________________________________
# ngpu: Constants
#__________________
const NoFile * = "UndefinedFile.ext"

#_______________________________________
# ngpu: Errors
#__________________
type DrawError * = object of IOError
type InitError * = object of IOError
type LoadError * = object of IOError
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
type AdapterBase * = ref object of RootObj
  ## Base Adapter. Used only for no-window apps.
  ct       *:wgpu.Adapter
  cfg      *:wgpu.RequestAdapterOptions
  label    *:str
type Adapter * = ref object of AdapterBase
  surface  *:wgpu.Surface
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
#__________________
type Buffer *[T]= ref object
  data   *:T
  ct     *:wgpu.Buffer
  cfg    *:wgpu.BufferDescriptor
  label  *:str


#_______________________________________
# ngpu: Core
#__________________
type Renderer * = ref object of RootObj
  ## Rendering core
  label      *:str
  win        *:Window
  bg         *:Color
  instance   *:Instance
  adapter    *:Adapter
  device     *:Device
  swapChain  *:Swapchain
  # cam        *:Camera
  # tech       *:RenderTechs
#__________________
type Minimal * = ref object of RootObj
  ## Minimal core
  label     *:str
  instance  *:Instance
  adapter   *:AdapterBase
  device    *:Device
#__________________
type Compute * = ref object of RootObj
  ## Compute-only core
  label     *:str



#_______________________________________
# ngpu: Tech
#__________________
# Elements
const VertMain * = "vert"  ## Default name for the entry point of the vertex   shader
const FragMain * = "frag"  ## Default name for the entry point of the fragment shader
const CompMain * = "comp"  ## Default name for the entry point of the compute  shader
type  Shader   * = ref object
  ct     *:wgpu.ShaderModule
  cfg    *:wgpu.ShaderModuleDescriptor
  label  *:str
  code   *:str
  file   *:str
#__________________
type VertexLayout * = ref object
  ct    *:wgpu.VertexBufferLayout
  attr  *:wgpu.VertexAttribute
type MeshShape * = seq[VertexLayout]
##[
  ct    *:seq[wgpu.VertexBufferLayout]  ## Data passed to wgpu as it wants it.
  inner *:seq[VertexLayout]             ## Properties/Data of the VertexBufferLayout. Must match ct.len
  # NOTE: Contains some duplicate data.
  # VertexBufferLayout is an array, and it wants an array of VertexAttribute inside it.
  # - If we use a seq[VertexBufferLayout], we can send the data as it is to wgpu (aka the purpose of the `ct` field),
  #   but we no longer have the inner array pointer the moment we exit the constructor.
  # - If we use a seq[VertexLayout] we solve the inner array issue (aka the purpose of the `inner` field),
  #   but we are no longer able to send the data as it is on our side.
  # I don't like this, but I currently don't know any other alternative.
  # TODO: ?? Can we create a seq[VertexBufferLayout] with the data contained in inner.ct directly ?? ??
  #       (currently copying it, so its duplicate. but maybe we can reference instead in some way)
]##
#__________________
type PipelineLayout * = ref object
  ct       *:wgpu.PipelineLayout
  cfg      *:wgpu.PipelineLayoutDescriptor
  label    *:str
#__________________
type Pipeline  * = ref object
  shader    *:Shader
  meshShape *:MeshShape
  layout    *:PipelineLayout
  ct        *:wgpu.RenderPipeline
  cfg       *:wgpu.RenderPipelineDescriptor
  label     *:str
#__________________
type Texture * = ref object
  ct       *:wgpu.Texture
  view     *:wgpu.TextureView
  label    *:str

#__________________
when defined(debug):
  const ColorClear *:Color= color(1.0, 0.0, 0.5, 1.0)
else:
  const ColorClear *:Color= color(0.1, 0.1, 0.1, 1.0)
#__________________
type Target *{.pure.}= enum  Color, ColorD, ColorDS
#__________________
type RenderTarget * = ref object
  case kind*:Target
  of Target.Color:    discard
  of Target.ColorD:   depth         *:wgpu.RenderPassDepthStencilAttachment
  of Target.ColorDS:  depthStencil  *:wgpu.RenderPassDepthStencilAttachment
  texture  *:Texture
  color    *:seq[wgpu.RenderPassColorAttachment]
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

